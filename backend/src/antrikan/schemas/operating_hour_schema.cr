module Antrikan
  class OperatingHourSchema < BaseSchema
    field :day, :int, required: true
    field :open_time, :duration, required: true
    field :close_time, :duration, required: true
  end
end
