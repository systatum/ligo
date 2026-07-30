module Antrikan
  class Channel::UpdaterService < BaseService(Channel)
    include FileUploader

    def initialize(@channel : Channel, @data : Marten::HTTP::Params::Data)
    end

    def run : ServiceResult(Channel)
      return failure(schema.errors) unless schema.valid?

      begin
        update_fields
        success(@channel)
      rescue ex : ::Errors::LogoUploadException
        failure(ex.errors)
      rescue ex : Marten::DB::Errors::InvalidRecord
        failure(ex.record.errors)
      end
    end

    private def update_fields
      description = schema.description? ? schema.description : nil
      @channel.name = schema.name if schema.name?
      @channel.description = description if @data.has_key?("description")
      @channel.logo_file_id = upload_image(schema.logo) if @data.has_key?("logo")
      @channel.predeletable_state = schema.predeletable_state!.value if schema.predeletable_state?
      @channel.enforce_operating_hours = schema.enforce_operating_hours! if schema.enforce_operating_hours?
      @channel.max_item_piece = schema.max_item_piece! if schema.max_item_piece?
      @channel.parent_channel = Channel.get_by_hashed_id!(schema.parent_channel_id!) if schema.parent_channel_id?

      @channel.save!
    end

    private def schema
      @schema ||= ChannelUpdateSchema.new(@data)
    end
  end
end
