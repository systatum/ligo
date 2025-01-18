module Auth
  ROUTES = Marten::Routing::Map.draw do
    path "/reset-password/initiate", PasswordResetInitiateHandler, name: "password_reset_initiate"
    path "/reset-password/confirm/<uid:str>/<token:str>", PasswordResetConfirmHandler, name: "password_reset_confirm"

    path "/api/user/signup", SignUpHandler, name: "api_sign_up"
    path "/api/user/signin", SignInHandler, name: "api_sign_in"
    path "/api/user/update_password", PasswordUpdateHandler, name: "api_update_password"
    path "/api/user/request_password_reset", PasswordResetInitiateHandler, name: "api_request_password_reset"
  end
end
