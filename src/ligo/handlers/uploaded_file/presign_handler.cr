class UploadedFilePresignHandler < RequestHandler
  protect_from_forgery false
  http_method_names :post

  before_dispatch :feature_must_be_enabled

  def post : Marten::HTTP::Response
    raise AuthorizationError.new unless current_user

    schema = Ligo::UploadedFile::PresignSchema.new(request.data)
    return render_invalid_payload(schema.errors) unless schema.valid?

    declared_size = schema.size_bytes!
    expires_at = PresignedUpload.authorize_hook.call(current_user!, declared_size)

    uploaded = Ligo::UploadedFile.create_opaque!(
      byte_size: declared_size,
      uploaded_by: current_user,
      expires_at: expires_at,
    )

    bucket = AppSettings.instance.ligo_uploaded_file_bucket
    upload_url = S3PresignerService.presigned_put_url(bucket, uploaded.id.to_s)

    json({
      storage_key: uploaded.id.to_s,
      upload_url:  upload_url,
      expires_at:  expires_at.try(&.to_rfc3339),
    }, status: 200)
  end

  private def feature_must_be_enabled
    head 404 unless AppSettings.instance.ligo_allow_presigned_upload
  end
end
