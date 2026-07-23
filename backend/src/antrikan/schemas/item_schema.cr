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
      return unless carousel_images?

      if carousel_images!.size > 6
        errors.add(:carousel_images, "cannot have more than 6 images")
      end
    end
  end
end
