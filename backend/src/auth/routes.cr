module Auth
  ROUTES = Marten::Routing::Map.draw do
    path "/api/user/signup", SignUpHandler, name: "api_sign_up"
    path "/api/user/signin", SignInHandler, name: "api_sign_in"
    path "/api/user/update_password", PasswordUpdateHandler, name: "api_update_password"
    path "/api/user/request_password_reset", PasswordResetInitiateHandler, name: "api_request_password_reset"

    path "/api/user/my-bio", MyBioUpdateHandler, name: "api_my_bio_update"
    path "/api/user/my-picture", MyPictureUploadHandler, name: "api_my_picture_upload"

    organization_routes = Marten::Routing::Map.draw do
      path "", OrganizationCreateHandler, name: "api_organization_create"
      path "/<hashed_id:str>", OrganizationUpdateHandler, name: "api_organization_update"
      path "/<hashed_id:str>/delete", OrganizationDeleteHandler, name: "api_organization_delete"
    end
    path "/api/organizations", organization_routes
  end
end
