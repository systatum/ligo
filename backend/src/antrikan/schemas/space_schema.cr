module Antrikan
  class SpaceSchema < BaseSchema
    # Each carousel item is either `{keep_id: <uuid>}` or a fresh upload payload
    # supporting "mix-and-match" updates
    struct CarouselImagePayload
      include JSON::Serializable

      # keep this already-uploaded image, just place it <here> (at certian pos)
      property keep_id : String?

      # a fresh upload spot these two fields
      property base64_bytes : String?
      property mimetype : String?
    end

    field :name, :string, max_size: 255, required: true, strip: true
    field :need_manual_approval, :bool, required: false
    field :has_operating_hours, :bool, required: false
    field :require_registered_queuer, :bool, required: false
    field :logo, :json, required: false, serializable: FilePayload
    field :carousel_images, :array, required: false, of: :json, serializable: CarouselImagePayload
    field :address, :string, required: false
    field :phone, :string, required: false
    field :email, :email, required: false
    field :business_name, :string, max_size: 255, required: false, strip: true

    validate :validate_carousel_images_size

    private def validate_carousel_images_size
      return unless carousel_images?

      if carousel_images!.size > 6
        errors.add(:carousel_images, "cannot have more than 6 images")
      end
    end
  end
end
