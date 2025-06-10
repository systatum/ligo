module Auth
  class OrganizationSchema < BaseSchema
    field :name, :string, max_size: 255
  end
end
