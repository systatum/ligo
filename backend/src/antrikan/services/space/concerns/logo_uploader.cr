module Antrikan
  module Space::LogoUploader
    def handle_logo_upload
      if schema.logo
        file_payload = schema.logo.not_nil!

        unless file_payload.media_type.type == "image"
          raise LogoUploadException.new(:logo, "must be of 'image' mimetype")
        end

        fs_result = FileStagerService.new(file_payload).run
        raise LogoUploadException.new(fs_result.errors) unless fs_result.success?

        fc_result = FileCommitterService.new(fs_result.data.not_nil!).run
        raise LogoUploadException.new(fc_result.errors) unless fc_result.success?

        committed_file = fc_result.data.not_nil!

        schema.validated_data["logo_file_id"] = committed_file.id
      end

      # not needed anymore
      schema.validated_data.delete("logo")

      nil
    end
  end
end
