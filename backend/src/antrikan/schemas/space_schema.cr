module Antrikan
  class SpaceSchema < BaseSchema
    field :name, :string, max_size: 255, required: true, strip: true
    field :need_manual_approval, :bool, required: false
    field :has_operating_hours, :bool, required: false
    field :require_registered_queuer, :bool, required: false
    field :logo, :json, required: false, serializable: FilePayload
    field :carousel_images, :array, required: false, of: :json, serializable: CarouselImagePayload
    field :address, :string, max_size: 255, required: false
    field :address_city_code, :int, required: false
    field :address_postal_code, :string, max_size: 20, required: false
    field :latitude, :float, required: false
    field :longitude, :float, required: false
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
