module Antrikan::OperatingHourHelper
  @op_hour : OperatingHour?
  @op_hour_schema : OperatingHourSchema?
  @channel : Channel?
  @item : Item?
  @space : Space?

  private def owner?
    return owner_of_channel? if params.has_key?("channel_hashed_id")
    return owner_of_item? if params.has_key?("item_slug")

    owner_of_space?
  end

  private def owner_of_space?
    space.owned_by?(current_user!)
  end

  private def owner_of_channel?
    channel.space!.owned_by?(current_user!)
  end

  private def owner_of_item?
    item.channel!.space!.owned_by?(current_user!)
  end

  private def assign_operating_hour_owner!(op_hour : OperatingHour)
    if params.has_key?("channel_hashed_id")
      op_hour.channel = channel
      return
    end

    if params.has_key?("item_slug")
      op_hour.item = item
      return
    end

    op_hour.space = space
  end

  private def op_hour
    @op_hour ||= find_op_hour
  end

  private def find_op_hour
    hashed_id = params["operating_hour_hashed_id"].to_s

    if params.has_key?("channel_hashed_id")
      return OperatingHour.filter_by_hashed_id(hashed_id).get!(channel_id: channel.id)
    end

    if params.has_key?("item_slug")
      return OperatingHour.filter_by_hashed_id(hashed_id).get!(item_id: item.id)
    end

    OperatingHour.filter_by_hashed_id(hashed_id).get!(space_id: space.id)
  end

  private def op_hour_scope
    if params.has_key?("channel_hashed_id")
      return OperatingHour.filter(channel_id: channel.id, deleted_at: nil)
    end

    if params.has_key?("item_slug")
      return OperatingHour.filter(item_id: item.id, deleted_at: nil)
    end

    OperatingHour.filter(space_id: space.id, deleted_at: nil)
  end

  private def channel
    @channel ||= Channel.filter_by_hashed_id(params["channel_hashed_id"].to_s).get!
  end

  private def item
    @item ||= Item.filter_by_slug(params["item_slug"].to_s).get!
  end

  private def space
    @space ||= Space.filter_by_hashed_id(params["space_hashed_id"].to_s).get!
  end

  private def op_hour_schema
    @op_hour_schema ||= OperatingHourSchema.new(request.data)
  end

  private def normalize_duration_params!
    ["open_time", "close_time"].each do |k|
      next unless request.data[k]
      s = extract_param_string?(request.data[k])
      request.data[k] = [Converter.normalize_time_notation(s)] if s
    end
  end

  private def extract_param_string?(val) : String?
    case val
    when String
      val
    when JSON::Any
      val.as_s?
    else
      nil
    end
  end
end
