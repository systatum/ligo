require "./organization_factory"

def create_product(
  organization = create_organization,
  short_description = "",
  note = nil,
)
  n = Product.last.nil? ? 1 : (Product.last!.id! + 1)

  prod = Product.new(organization: organization)
  prod.name = "Prod #{n}"
  prod.short_description = short_description
  prod.note = note
  prod.save!

  prod
end
