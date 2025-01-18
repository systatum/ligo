enum Role
  # in the order of commonality, before being further specialized:

  GUEST            # perhaps, haven't fully joined, or an external collaborator
  STAFF            # everyone, with default, basic rights
  PART_TIME_STAFF  # includes interns
  FULL_TIME_STAFF  # basic rights enjoyed by any full-time staff
  OWNER            # can create chief staffs, etc, the absolute owner, can assign/remove another's owner role
  CHIEF_STAFF      # can't create other chief stafs, but similar to owners
  HR_STAFF         # can't remove management, but can deactivate team lead, for example
  MANAGER          # can't remove other higher up, let alone owner, but can manage staff; a team lead
  BUSINESS_STAFF   # includes finances, marketing, and bizdev staff
  PRODUCTION_STAFF # includes designer, engineer, etc
  OPERATION_STAFF  # includes customer-service, concierge, in-field staff
  SECURITY_STAFF   # includes "office boy", assistant, etc

  # in the future, we will be able to set the role in such a fine-grained fashion
end
