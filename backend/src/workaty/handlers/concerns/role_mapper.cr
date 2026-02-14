module Workaty::RoleMapper
  ROLE_TO_RBACR = {
    Auth::Role::OWNER            => "owner",
    Auth::Role::CHIEF_STAFF      => "chief_staff",
    Auth::Role::HR_STAFF         => "hr_staff",
    Auth::Role::MANAGER          => "manager",
    Auth::Role::BIZDEV_STAFF     => "bizdev_staff",
    Auth::Role::FINANCE_STAFF    => "finance_staff",
    Auth::Role::MARKETING_STAFF  => "marketing_staff",
    Auth::Role::BUSINESS_STAFF   => "business_staff",
    Auth::Role::PRODUCTION_STAFF => "production_staff",
    Auth::Role::OPERATION_STAFF  => "operation_staff",
    Auth::Role::FULL_TIME_STAFF  => "full_time_staff",
    Auth::Role::PART_TIME_STAFF  => "part_time_staff",
    Auth::Role::STAFF            => "staff",
    Auth::Role::SECURITY_STAFF   => "security_staff",
    Auth::Role::GUEST            => "guest",
    Auth::Role::CUSTOMER         => "customer",
  }

  def self.map_user_role_to_rbacr(user : Auth::User) : String
    ROLE_TO_RBACR.fetch(user.role!, "guest")
  end
end
