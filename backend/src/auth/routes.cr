module Auth
  ROUTES = Marten::Routing::Map.draw do
    path "/api/user/signup", SignUpHandler, name: "api_sign_up"
    path "/api/user/signin", SignInHandler, name: "api_sign_in"
    path "/api/user/update_password", PasswordUpdateHandler, name: "api_update_password"
    path "/api/user/request_password_reset", PasswordResetInitiateHandler, name: "api_request_password_reset"

    path "/api/user/my-bio", MyBioShowHandler, name: "api_my_bio_show"
    path "/api/user/my-bio/update", MyBioUpdateHandler, name: "api_my_bio_update"
    path "/api/user/my-picture", MyPictureUploadHandler, name: "api_my_picture_upload"

    realm_routes = Marten::Routing::Map.draw(:realm) do
      path "/create", RealmCreateHandler, name: "create"

      oauth_routes = Marten::Routing::Map.draw(:oauth) do
        path "/<provider:str>", OAuthInitiateHandler, name: "initiate"
        path "/<provider:str>/callback", OAuthCallbackHandler, name: "callback"
      end
      path "/<realm_id:str>/oauth", oauth_routes
    end

    path "/api/user/request-email-verification", RequestEmailVerificationHandler, name: "api_request_email_verification"
    path "/api/user/verify-email/confirm", EmailVerifyHandler, name: "api_verify_email"
    path "/api/user/verify-email/form", EmailVerificationFormHandler, name: "api_verify_email_form"

    path "/api/request_state", RequestStateHandler, name: "api_request_state"

    organization_routes = Marten::Routing::Map.draw do
      path "/create", OrganizationCreateHandler, name: "api_organization_create"
      path "/<hashed_id:str>", OrganizationUpdateHandler, name: "api_organization_update"
      path "/<hashed_id:str>/delete", OrganizationDeleteHandler, name: "api_organization_delete"
    end

    path "/api/webhooks/iam", Auth::IamWebhookHandler, name: "api_iam_webhook"

    path "/api/realm", realm_routes
    path "/api/organizations", organization_routes
  end
end
