# This module define roles, permissions and privileges specific to Workaty
module Auth
  class Authorizer
    include Rbacr::Definer

    MANAGE = act(:manage)

    CAN_MANAGE_EMAIL_TEMPLATE = can(MANAGE, :email_template)

    OWNER_ROLE            = role(:owner, [CAN_MANAGE_EMAIL_TEMPLATE], Rbacr::Tier::DIRECTOR)
    CHIEF_STAFF_ROLE      = role(:chief_staff, [CAN_MANAGE_EMAIL_TEMPLATE], Rbacr::Tier::DIRECTOR)
    HR_STAFF_ROLE         = role(:hr_staff, [CAN_MANAGE_EMAIL_TEMPLATE], Rbacr::Tier::MANAGER)
    MANAGER_ROLE          = role(:manager, [CAN_MANAGE_EMAIL_TEMPLATE], Rbacr::Tier::MANAGER)
    BIZDEV_STAFF_ROLE     = role(:bizdev_staff, tier: Rbacr::Tier::MANAGER)
    FINANCE_STAFF_ROLE    = role(:finance_staff, tier: Rbacr::Tier::MANAGER)
    MARKETING_STAFF_ROLE  = role(:marketing_staff, tier: Rbacr::Tier::MANAGER)
    BUSINESS_STAFF_ROLE   = role(:business_staff, tier: Rbacr::Tier::MANAGER)
    PRODUCTION_STAFF_ROLE = role(:production_staff)
    OPERATION_STAFF_ROLE  = role(:operation_staff)
    FULL_TIME_STAFF_ROLE  = role(:full_time_staff)
    PART_TIME_STAFF_ROLE  = role(:part_time_staff)
    STAFF_ROLE            = role(:staff)
    SECURITY_STAFF_ROLE   = role(:security_staff)
    GUEST_ROLE            = role(:guest)
    CUSTOMER_ROLE         = role(:customer)
  end
end
