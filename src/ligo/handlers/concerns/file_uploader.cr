# Handles file uploads from a file payload.
# Stages and commits the file through the standard pipeline, returning the resulting file ID.
module FileUploader
  private def upload_image(file_payload : FilePayload?, uploaded_by : Ligo::User? = nil) : UUID?
    return nil unless file_payload

    media_type = file_payload.media_type
    unless media_type && media_type.type == "image"
      raise ::Errors::LogoUploadException.new("must be an image (image/*)")
    end

    fs_result = FileStagerService.new(file_payload).run
    unless fs_result.success?
      raise ::Errors::LogoUploadException.new("staging failed: #{fs_result.errors}")
    end

    staged = fs_result.data.not_nil!
    fc_result = FileCommitterService.new(staged, uploaded_by).run
    unless fc_result.success?
      raise ::Errors::LogoUploadException.new("commit failed: #{fc_result.errors}")
    end

    fc_result.data.not_nil!.id
  end
end
