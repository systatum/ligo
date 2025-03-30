def create_organization
  o = Auth::Organization.new
  n = Auth::Organization.last.nil? ? 1 : (Auth::Organization.last!.id! + 1)
  o.name = "Org #{n}"
  o.save!

  o
end
