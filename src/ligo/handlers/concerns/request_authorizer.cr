# Generic RBAC delegation for handlers, backed by the rbacr shard. This is
# deliberately not mixed into RequestHandler by default, since not every
# handler has a notion of roles/privileges.
#
# To use it, include this into your own app's base handler and implement
# `authorizer_class`, returning whichever class in your app includes
# Rbacr::Definer with your own roles and privileges, e.g.:
#
# ```
# class MyApp::Authorizer
#   include Rbacr::Definer
#   MANAGE            = act(:manage)
#   CAN_MANAGE_WIDGET = can(MANAGE, :widget)
#   OWNER_ROLE        = role(:owner, [CAN_MANAGE_WIDGET])
# end
#
# class MyApp::RequestHandler < RequestHandler
#   include RequestAuthorizer
#
#   def authorizer_class
#     MyApp::Authorizer
#   end
# end
# ```
module RequestAuthorizer
  abstract def authorizer_class

  def can?(act : Rbacr::Act, resource, roles : String | Array(String)) : Bool
    authorizer_class.can?(act, resource, roles)
  end

  def can?(privilege : Rbacr::Privilege, roles : String | Array(String)) : Bool
    authorizer_class.can?(privilege, roles)
  end

  def can?(privilege_id : String | Symbol, roles : String | Array(String)) : Bool
    authorizer_class.can?(privilege_id, roles)
  end
end
