def create_organization
  o = Organization.new
  n = Organization.last.nil? ? 1 : (Organization.last!.id! + 1)
  o.name = "Org #{n}"
  o.save!

  o
end
