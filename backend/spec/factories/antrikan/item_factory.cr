require "./channel_factory"

def create_item(
  channel : Antrikan::Channel = create_channel,
  name : String = "8AM",
  order : Int32 = 0,
  daily_cap : Int32 = 0,
  unit_price : Int64 = 0_i64,
  is_monitored : Bool = false,
  description : String? = nil,
  main_image_file_id : UUID? = nil,
) : Antrikan::Item
  item = Antrikan::Item.new
  item.channel = channel
  item.name = name
  item.order = order
  item.daily_cap = daily_cap
  item.unit_price = unit_price
  item.is_monitored = is_monitored
  item.description = description
  item.main_image_file_id = main_image_file_id
  item.save!

  item
end
