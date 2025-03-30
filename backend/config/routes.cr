# The main routes map associates routes to handlers.
# For more information please see: https://martenframework.com/docs/handlers-and-http/routing
Marten.routes.draw do
  path "/", HomeHandler, name: "root"
  path "/auth", Auth::ROUTES, name: "auth"
  path "/api/app_info", AppInfoHandler, name: "app_info"

  path "/api/products", ProductCreateHandler, name: "api_product_create"
  path "/api/products/<id:str>", ProductStateHandler, name: "api_product_show"
  path "/api/products/<id:str>", ProductStateHandler, name: "api_product_update"
  path "/api/products/<id:str>", ProductStateHandler, name: "api_product_delete"

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
