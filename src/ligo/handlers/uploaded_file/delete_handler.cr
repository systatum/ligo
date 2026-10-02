class UploadedFileDeleteHandler < RequestHandler
  protect_from_forgery false
  http_method_names :delete

  before_dispatch :feature_must_be_enabled

  def delete : Marten::HTTP::Response
    raise AuthorizationError.new unless current_user

    file = uploaded_file
    return head 404 if file.nil?

    bucket = AppSettings.instance.ligo_uploaded_file_bucket
    S3PresignerService.delete_object(bucket, file.id.to_s)
    file.delete

    head 204
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
