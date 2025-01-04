enum Role
  # in the order of relative superiority:

  OWNER # can create managers
  MANAGEMENT # can create chief stafs, but can't remove owner
  HR_STAFF # can't remove management, but can deactivate team lead, for example
  TEAM_LEAD # can't remove management or other higher up, let alone owner, but can manage staff
  BUSINESS_STAFF # includes finances, marketing, and bizdev staff
  PRODUCTION_STAFF # includes designer, engineer, etc
  SECURITY_STAFF # includes "office boy", assistant, etc
  PART_TIME_STAFF # includes interns
  GUEST # perhaps, haven't fully joined, or an external collaborator

  # in the future, we will be able to set the role in such a fine-grained fashion
end
