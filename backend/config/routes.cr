# The main routes map associates routes to handlers.
# For more information please see: https://martenframework.com/docs/handlers-and-http/routing
Marten.routes.draw do
  path "/", HomeHandler, name: "root"
  path "/email", EmailSenderHandler, name: "email_sender"
  path "/auth", Auth::ROUTES, name: "auth"
  path "/antrikan", Antrikan::ROUTES, name: "antrikan"
  path "/workaty", Workaty::ROUTES, name: "workaty"

  path "/ping", PingHandler, name: "ping"

  path "/api/app_info", AppInfoHandler, name: "app_info"

  path "/api/products", ProductCreateHandler, name: "api_product_create"
  path "/api/products/<id:str>", ProductStateHandler, name: "api_product_show"
  path "/api/products/<id:str>", ProductStateHandler, name: "api_product_update"
  path "/api/products/<id:str>", ProductStateHandler, name: "api_product_delete"

  field_routes = Marten::Routing::Map.draw(:field) do
    path "/", FieldCreateHandler, name: "create"
    path "/<field_hashed_id:str>/update", FieldUpdateHandler, name: "update"
    path "/<field_hashed_id:str>/delete", FieldDeleteHandler, name: "delete"
    path "/rt/<resource_type:str>/index", FieldIndexHandler, name: "index"
  end

  path "/api/field", field_routes

  if Marten.env.development?
    path "#{Marten.settings.assets.url}<path:path>", Marten::Handlers::Defaults::Development::ServeAsset, name: "asset"
    path "#{Marten.settings.media_files.url}<path:path>", Marten::Handlers::Defaults::Development::ServeMediaFile, name: "media_file"
  end
end
