class Organization < Marten::Model
  include ChangeTracker
  include SoftDeleter

  field :id, :big_int, primary_key: true, auto: true
  field :name, :string, max_size: 255, null: false, blank: false
end
