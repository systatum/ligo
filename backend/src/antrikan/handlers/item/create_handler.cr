module Antrikan
  class ItemCreateHandler < RequestHandler
    include ChannelHelper
    include ItemHelper

    protect_from_forgery false
    http_method_names :post

    def post : Marten::HTTP::Response
      raise Marten::HTTP::Errors::PermissionDenied.new unless authorized_for_channel?

      if schema.valid?
        it = Item.new
        it.channel = channel

        data = schema.validated_data
        it.name = data["name"].as(String)

        it.order = data["order"].as(Int32 | Int64).to_i if data["order"]?
        it.daily_cap = data["daily_cap"].as(Int32 | Int64).to_i if data["daily_cap"]?
        it.unit_price = data["unit_price"].as(Int32 | Int64).to_i64 if data["unit_price"]?
        it.unit_currency = schema.unit_currency!.value if schema.unit_currency?
        it.is_monitored = data["is_monitored"].as(Bool) if data["is_monitored"]?

        desc = data["description"]?.as?(String)
        it.description = desc.nil? || desc.empty? ? nil : desc

        it.main_image_file_id = upload_image(schema.main_image)

        if schema.carousel_images?
          result = CarouselImagesResolverService.new(schema.carousel_images!).run
          return render_invalid_payload(result.errors) unless result.success?
          it.carousel_image_ids = UploadedFileIds.new(ids: result.data.not_nil!)
        end

        it.save!
        json ItemSerializer.serialize(it), status: 201
      else
        render_invalid_payload(schema)
      end
    rescue ex : ::Errors::LogoUploadException
      render_invalid_payload(ex.errors)
    end
  end
end
