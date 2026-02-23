require "./space_factory"

def create_operating_hour(
  space : Antrikan::Space = create_space,
  day : Int32 = 0,
  open_time : Time::Span = Time::Span.new(hours: 9, minutes: 0),
  close_time : Time::Span = Time::Span.new(hours: 17, minutes: 0),
) : Antrikan::OperatingHour
  operating_hour = Antrikan::OperatingHour.new
  operating_hour.space = space
  operating_hour.day = day
  operating_hour.open_time = open_time
  operating_hour.close_time = close_time
  operating_hour.save!

  operating_hour
end
