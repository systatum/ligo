def create_organization
  o = Organization.new
  o.name = "The Best Organization"
  o.save!

  o
end
