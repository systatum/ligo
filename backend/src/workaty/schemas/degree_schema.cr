module Workaty
  class DegreeSchema < BaseSchema
    field :institution, :string, max_size: 255, required: true, strip: true
    field :level, :enum, values: Workaty::Degree::Level, required: true
    field :major_field, :string, max_size: 255, required: false, strip: true
    field :obtained_at, :date, required: false
  end
end
