Marten.routes.draw do
  path "/uploaded_file/<id:uuid>", UploadedFileShowHandler, name: "uploaded_file_show"
  path "/job/<id:str>", JobStatusHandler, name: "job_status"

  path "/realm/create", Ligo::RealmCreateHandler, name: "realm_create"
  path "/realm/<realm_id:str>/oauth/<provider:str>", Ligo::OAuthInitiateHandler, name: "realm_oauth_initiate"
  path "/realm/<realm_id:str>/oauth/<provider:str>/callback", Ligo::OAuthCallbackHandler, name: "realm_oauth_callback"

  path "/webhooks/iam", Ligo::IamWebhookHandler, name: "iam_webhook"

  path "/user/signup", Ligo::SignUpHandler, name: "sign_up"
  path "/user/signin", Ligo::SignInHandler, name: "sign_in"

  path "/user/bio", Ligo::BioShowHandler, name: "bio_show"
  path "/user/bio/update", Ligo::BioUpdateHandler, name: "bio_update"
  path "/user/my-picture", Ligo::MyPictureUploadHandler, name: "my_picture_upload"
end
