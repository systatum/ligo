module Workaty
  class CandidateSchema < Marten::Schema
    field :first_name, :string, max_size: 128, required: true, strip: true
    field :last_name, :string, max_size: 128, required: false, strip: true
    field :fitness, :enum, values: Workaty::Candidate::Fitness, required: false
    field :note, :string, required: false, strip: true
  end
end
