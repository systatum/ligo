# The main routes map associates routes to handlers.
# For more information please see: https://martenframework.com/docs/handlers-and-http/routing
Marten.routes.draw do
  path "/", HomeHandler, name: "root"
  path "/auth", Auth::ROUTES, name: "auth"
  path "/api/app_info", AppInfoHandler, name: "app_info"

  path "/api/organizations", OrganizationCreateHandler, name: "api_organization_create"
  path "/api/organizations/<pk:int>", OrganizationStateHandler, name: "api_organization_update"
  path "/api/organizations/<pk:int>", OrganizationStateHandler, name: "api_organization_delete"

  path "/api/products", ProductCreateHandler, name: "api_product_create"
  path "/api/products/<pk:int>", ProductStateHandler, name: "api_product_show"
  path "/api/products/<pk:int>", ProductStateHandler, name: "api_product_update"
  path "/api/products/<pk:int>", ProductStateHandler, name: "api_product_delete"

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
