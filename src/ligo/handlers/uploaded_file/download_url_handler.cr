class UploadedFileDownloadUrlHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  before_dispatch :feature_must_be_enabled

  def get : Marten::HTTP::Response
    raise AuthorizationError.new unless current_user

    file = uploaded_file
    return head 404 if file.nil?
    return head 404 if file.expires_at.try(&.< Time.local)

    bucket = AppSettings.instance.ligo_uploaded_file_bucket
    download_url = S3PresignerService.presigned_get_url(bucket, file.id.to_s)

    json({download_url: download_url}, status: 200)
  end

  private def feature_must_be_enabled
    head 404 unless AppSettings.instance.ligo_allow_presigned_upload
  end

  private def uploaded_file : Ligo::UploadedFile?
    Ligo::UploadedFile.get(id: params["id"])
  rescue
    nil
  end
end
