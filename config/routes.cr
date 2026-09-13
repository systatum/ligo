Marten.routes.draw do
  path "/uploaded_file/<id:uuid>", UploadedFileShowHandler, name: "uploaded_file_show"
  path "/job/<id:str>", JobStatusHandler, name: "job_status"

  path "/realm/create", Ligo::RealmCreateHandler, name: "realm_create"
  path "/realm/<realm_id:str>/oauth/<provider:str>", Ligo::OAuthInitiateHandler, name: "realm_oauth_initiate"
  path "/realm/<realm_id:str>/oauth/<provider:str>/callback", Ligo::OAuthCallbackHandler, name: "realm_oauth_callback"

  path "/webhooks/iam", Ligo::IamWebhookHandler, name: "iam_webhook"

  path "/user/signup", Ligo::SignUpHandler, name: "sign_up"
  path "/user/signin", Ligo::SignInHandler, name: "sign_in"

  path "/user/update_password", Ligo::PasswordUpdateHandler, name: "update_password"
  path "/user/request_password_reset", Ligo::PasswordResetInitiateHandler, name: "request_password_reset"
  path "/user/reset_password/confirm", Ligo::PasswordResetConfirmHandler, name: "reset_password_confirm"

  path "/user/bio", Ligo::BioShowHandler, name: "bio_show"
  path "/user/bio/update", Ligo::BioUpdateHandler, name: "bio_update"
  path "/user/my-picture", Ligo::MyPictureUploadHandler, name: "my_picture_upload"

  path "/user/request-email-verification", Ligo::RequestEmailVerificationHandler, name: "request_email_verification"
  path "/user/verify-email/confirm", Ligo::EmailVerifyHandler, name: "verify_email"
  path "/user/verify-email/form", Ligo::EmailVerificationFormHandler, name: "verify_email_form"

  path "/request_state", Ligo::RequestStateHandler, name: "request_state"

  path "/fields/create", FieldCreateHandler, name: "field_create"
  path "/fields/<field_hashed_id:str>/update", FieldUpdateHandler, name: "field_update"
  path "/fields/<field_hashed_id:str>/delete", FieldDeleteHandler, name: "field_delete"
  path "/fields/rt/<resource_type:int>/index", FieldIndexHandler, name: "field_index"
end
