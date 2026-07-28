module Antrikan
  class SpaceSchema < BaseSchema
    field :name, :string, max_size: 255, required: true, strip: true
    field :description, :string, required: false
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
      validate_max_images(:carousel_images, carousel_images, 6)
    end
  end
end
