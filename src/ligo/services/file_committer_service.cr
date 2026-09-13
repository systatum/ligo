class FileCommitterService < BaseService(Ligo::UploadedFile)
  @storage : Marten::Core::Storage::Base

  def initialize(@tmpFile : Marten::HTTP::UploadedFile, @uploaded_by : Ligo::User? = nil)
    @storage = Marten.media_files_storage
  end

  def run : ServiceResult(Ligo::UploadedFile)
    file_id = generate_file_id
    key = file_id.to_s

    begin
      @storage.write(key, @tmpFile.io)

      uploaded = Ligo::UploadedFile.new
      uploaded.id = file_id
      uploaded.original_name = detect_original_name(key)
      uploaded.content_type = detect_content_type
      uploaded.byte_size = @tmpFile.size.to_i64
      uploaded.uploaded_by = @uploaded_by || Current.user

      uploaded.save!

      success(uploaded)
    rescue e
      rollback_committed_file(key)

      failure("Failed committing file: #{e.message}")
    end
  end

  private def detect_content_type : String
    filename = @tmpFile.filename
    return "application/octet-stream" if filename.nil? || filename.empty?

    MIME.from_filename(filename)
  rescue
    "application/octet-stream"
  end

  private def detect_original_name(fallback : String) : String
    filename = @tmpFile.filename
    return fallback if filename.nil? || filename.empty?

    filename
  end

  protected def generate_file_id : UUID
    UUID.random
  end

  private def rollback_committed_file(key : String)
    return unless @storage.exists?(key)
    @storage.delete(key)
  rescue ex
    Logger.error("Failed to rollback committed file (key=#{key})", err: ex)
  end
end
