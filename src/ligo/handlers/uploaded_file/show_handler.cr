class UploadedFileShowHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  before_dispatch :resource_must_exist
  before_dispatch :resource_must_not_in_cache!

  after_dispatch :add_cache_headers

  @uploaded_file : Ligo::UploadedFile?

  def get : Marten::HTTP::Response
    file = uploaded_file.not_nil!
    content = Marten.media_files_storage.open(file.id.to_s)

    resp = respond(
      streamed_content: content.each_string,
      content_type: file.content_type.not_nil!,
    )

    resp.headers["Content-Type"] = file.content_type.not_nil!
    resp.headers["Content-Length"] = file.byte_size.not_nil!.to_s

    resp
  rescue ex : IO::Error | Marten::Core::Storage::Errors::FileNotFound
    handle_error ex
  rescue ex : XML::Error
    # Missing binary from storage could raise an XML parse error
    # from the S3 client path (empty error body)
    handle_error ex
  end

  private def handle_error(ex)
    Logger.error("Failed to get uploaded file", err: ex)
    head 404
  end

  private def resource_must_exist
    head 404 unless uploaded_file
  end

  private def resource_must_not_in_cache!
    file = uploaded_file
    return unless file

    last_modified = file.updated_at.not_nil!
    return unless request_not_modified?(last_modified: last_modified)

    resp = head(304)
    resp.headers["Cache-Control"] = IMMUTABLE_DATA_CONTROL_HEADER
    resp.headers["Last-Modified"] = HTTP.format_time(file.updated_at.not_nil!.to_utc)

    resp
  end

  private def add_cache_headers
    return unless uploaded_file
    file = uploaded_file.not_nil!
    set_response_immutable!(last_modified: file.updated_at.not_nil!)
  end

  private def uploaded_file : Ligo::UploadedFile?
    id = params["id"]
    @uploaded_file ||= Ligo::UploadedFile.get(id: id)
  rescue ex
    Logger.error("Failed to find file metadata (id=#{id})", err: ex)
    nil
  end
end
