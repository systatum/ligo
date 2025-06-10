class ProductSchema < BaseSchema
  field :name, :string, max_size: 255, required: false, strip: true
  field :short_description, :string, required: false, strip: true
  field :note, :string, required: false, strip: true
end
