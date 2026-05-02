module Antrikan
  class Item::UpdaterService < BaseService(Item)
    include FileUploader

    def initialize(@item : Item, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Item)
      return failure(schema.errors) unless schema.valid?

      begin
        update_fields
        success(@item)
      rescue ex : ::Errors::LogoUploadException
        failure(ex.errors)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def update_fields
      description = schema.description? ? schema.description : nil
      @item.name = schema.name if schema.name?
      @item.order = schema.order if schema.order?
      @item.daily_cap = schema.daily_cap if schema.daily_cap?
      @item.is_monitored = schema.is_monitored if schema.is_monitored?
      @item.description = description if @data.has_key?("description")
      @item.main_image_file_id = upload_image(schema.main_image) if @data.has_key?("main_image")

      @item.save!
    end

    private def schema
      @schema ||= ItemUpdateSchema.new(@data)
    end
  end
end
