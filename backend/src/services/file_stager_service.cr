# This service simply builds a Marten::HTTP::UploadedFile out of a FilePayload,
# the file payload is thus "staged" as a temporary file
class FileStagerService < BaseService(Marten::HTTP::UploadedFile)
  def initialize(@payload : FilePayload)
  end

  def run : ServiceResult(Marten::HTTP::UploadedFile)
    begin
      content = Base64.decode(@payload.base64_bytes)

      digest = Digest::SHA256.hexdigest(content)
      date_prefix = Time.utc.to_s("%Y%m%d")
      filename = "#{date_prefix}_#{digest}.#{@payload.media_type.sub_type}"

      part = HTTP::FormData::Part.new(
        HTTP::Headers{
          "Content-Disposition" => %(form-data; name="file_payload"; filename="#{filename}"),
        },
        IO::Memory.new(content)
      )

      return failure("Invalid file type") unless valid_file_type?(part.body, @payload.media_type)

      success(Marten::HTTP::UploadedFile.new(part))
    rescue ex
      return failure("Unexpected failure: #{ex.message}")
    end
  end

  private def valid_file_type?(io : IO, media_type : MIME::MediaType)
    case media_type.type
    when "image"
      return ImageSignature.valid?(io)
    else
      # handle other file types here
      return true
    end
  end
end
