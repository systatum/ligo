module Antrikan
  class RefundSchema < BaseSchema
    field :amount, :string, max_size: 255, required: true, strip: true # BigFloat
    field :reason, :string, max_size: 255, required: false
    # whether to allow it to go thru even if it would leave a negative refundable
    # balance on the target payment.
    field :forceful, :bool, required: false
    field :images, :array, required: false, of: :json, serializable: CarouselImagePayload

    validate :validate_images_size

    private def validate_images_size
      validate_max_images(:images, images, 2)
    end
  end
end
