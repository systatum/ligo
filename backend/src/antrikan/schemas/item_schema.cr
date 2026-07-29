module Antrikan
  class ItemSchema < BaseSchema
    field :name, :string, max_size: 255, required: true, strip: true
    field :order, :int, required: false
    field :daily_cap, :int, required: false
    field :unit_price, :int, required: false
    field :unit_currency, :enum, values: Antrikan::Currency, required: false
    field :is_monitored, :bool, required: false
    field :description, :string, required: false
    field :main_image, :json, required: false, serializable: FilePayload
    field :carousel_images, :array, required: false, of: :json, serializable: CarouselImagePayload

    validate :validate_carousel_images_size

    private def validate_carousel_images_size
      validate_max_images(:carousel_images, carousel_images, 6)
    end
  end
end
