module Antrikan
  # JSON-serializable wrapper persisted on `Space#carousel_image_ids` - an
  # ordered list of `UploadedFile` UUID strings. Not an ORM model (no table of
  # its own) and not input/output-shaped like a schema/serializer, so it lives
  # alongside other plain structs instead.
  class CarouselImageIds
    include JSON::Serializable

    property ids : Array(String)

    def initialize(@ids : Array(String) = [] of String)
    end
  end
end
