class OrganizationSchema < Marten::Schema
  field :name, :string, max_size: 255
end
