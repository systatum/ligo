module Auth
  ROUTES = Marten::Routing::Map.draw do
    path "/api/user/signup", SignUpHandler, name: "api_sign_up"
    path "/api/user/signin", SignInHandler, name: "api_sign_in"
    path "/api/user/update_password", PasswordUpdateHandler, name: "api_update_password"
    path "/api/user/request_password_reset", PasswordResetInitiateHandler, name: "api_request_password_reset"

    path "/api/organizations", OrganizationCreateHandler, name: "api_organization_create"
    path "/api/organizations/<pk:int>", OrganizationStateHandler, name: "api_organization_update"
    path "/api/organizations/<pk:int>", OrganizationStateHandler, name: "api_organization_delete"

    # this one is handled in the browser, not API
    path "/reset-password/confirm/<uid:str>/<token:str>", PasswordResetHandler, name: "password_reset"
  end
end
