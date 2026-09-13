# File content structure as a JSON-serializable object.
struct FilePayload
  include JSON::Serializable

  property base64_bytes : String
  property mimetype : String

  @[JSON::Field(ignore: true)]
  @_media_type : MIME::MediaType?

  def media_type : MIME::MediaType
    @_media_type ||= MIME::MediaType.parse(mimetype)
  end

  def after_initialize
    # early validate mimetype (which also loads it)
    media_type
  end
end
