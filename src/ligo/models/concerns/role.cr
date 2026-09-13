module Role
  # The one platform-level super admin account, above any organization's own
  # OWNER tier - not tied to a role value, just this specific verified email.
  SUPER_ADMIN_EMAIL = "adam@systatum.com"

  # in the order of commonality, before being further specialized:

  CUSTOMER         =    0 # simply a customer, shouldn't have admin access
  GUEST            = 1000 # perhaps, haven't fully joined, or an external collaborator
  STAFF            = 2000 # everyone, with default, basic rights
  PART_TIME_STAFF  = 2100 # includes interns
  FULL_TIME_STAFF  = 3000 # basic rights enjoyed by any full-time staff
  OWNER            = 9000 # can create chief staffs, etc, the absolute owner, can assign/remove another's owner role
  CHIEF_STAFF      = 8000 # can't create other chief stafs, but similar to owners
  HR_STAFF         = 7000 # can't remove management, but can deactivate team lead, for example
  MANAGER          = 6000 # includes team lead; can't remove other higher up, let alone owner, but can manage staff
  OPERATION_STAFF  = 5100 # includes customer-service, concierge, in-field staff
  PRODUCTION_STAFF = 5700 # includes designer, engineer, etc
  BUSINESS_STAFF   = 5900 # includes finances, marketing, and bizdev staff
  FINANCE_STAFF    = 5910
  MARKETING_STAFF  = 5920
  BIZDEV_STAFF     = 5930
  SECURITY_STAFF   = 4000 # includes "office boy", assistant, etc

  # in the future, we will be able to set the role in such a fine-grained fashion

  def self.admin?(user : Ligo::User?)
    return false unless user
    user.role! > Role::SECURITY_STAFF
  end

  def self.hr_staff?(user : Ligo::User?)
    return false unless user
    user.role! == Role::HR_STAFF
  end

  def self.at_least_bizdev?(user : Ligo::User?)
    return false unless user
    user.role! >= Role::BIZDEV_STAFF
  end

  def self.at_least_chief_staff?(user : Ligo::User?)
    return false unless user
    user.role! >= Role::CHIEF_STAFF
  end

  def self.owner?(user : Ligo::User?)
    return false unless user
    user.role! == Role::OWNER
  end

  def self.super_admin?(user : Ligo::User?)
    return false unless user
    user.email == SUPER_ADMIN_EMAIL && user.is_email_address_verified?
  end

  def self.must_at_least_bizdev!(user : Ligo::User?)
    raise AuthorizationError.new unless at_least_bizdev?(user)
  end
end
