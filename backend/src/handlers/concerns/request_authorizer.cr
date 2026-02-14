# Provides helper auth functions for request handlers
module RequestAuthorizer
  def can?(act : Rbacr::Act, resource, roles : String | Array(String)) : Bool
    Auth::Authorizer.can?(act, resource, roles)
  end

  def can?(privilege : Rbacr::Privilege, roles : String | Array(String)) : Bool
    Auth::Authorizer.can?(privilege, roles)
  end

  def can?(privilege_id : String | Symbol, roles : String | Array(String)) : Bool
    Auth::Authorizer.can?(privilege_id, roles)
  end
end
