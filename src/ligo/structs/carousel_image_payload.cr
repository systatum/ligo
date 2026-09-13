# Each carousel entry is either `{keep_id: <uuid>}` or a fresh upload payload,
# supporting "mix-and-match" updates. Shared by any resource with a
# `carousel_images` schema field.
struct CarouselImagePayload
  include JSON::Serializable

  # keep this already-uploaded image, just place it here (at this position)
  property keep_id : String?

  # a fresh upload spot these two fields
  property base64_bytes : String?
  property mimetype : String?
end
