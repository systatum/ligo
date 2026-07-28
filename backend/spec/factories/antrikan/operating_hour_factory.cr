require "./space_factory"
require "./channel_factory"
require "./item_factory"

def create_operating_hour(
  space : Antrikan::Space? = nil,
  channel : Antrikan::Channel? = nil,
  item : Antrikan::Item? = nil,
  day : Int32 = 0,
  open_time : Time::Span = Time::Span.new(hours: 9, minutes: 0),
  close_time : Time::Span = Time::Span.new(hours: 17, minutes: 0),
) : Antrikan::OperatingHour
  operating_hour = Antrikan::OperatingHour.new
  operating_hour.day = day
  operating_hour.open_time = open_time
  operating_hour.close_time = close_time

  if channel
    operating_hour.channel = channel
  elsif item
    operating_hour.item = item
  else
    operating_hour.space = space || create_space
  end

  operating_hour.save!

  operating_hour
end
