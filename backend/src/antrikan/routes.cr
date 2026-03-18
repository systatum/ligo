module Antrikan
  ROUTES = Marten::Routing::Map.draw do
    space_routes = Marten::Routing::Map.draw(:space) do
      path "/", SpaceCreateHandler, name: "create"
      path "/index", SpaceIndexHandler, name: "index"
      path "/<space_hashed_id:str>", SpaceShowHandler, name: "show"
      path "/<space_hashed_id:str>/update", SpaceUpdateHandler, name: "update"
      path "/<space_hashed_id:str>/delete", SpaceDeleteHandler, name: "delete"
      path "/<space_hashed_id:str>/qr", SpaceQrHandler, name: "qr"

      code_routes = Marten::Routing::Map.draw(:code) do
        path "/<space_code:str>", SpaceShowHandler, name: "show"
        path "/<space_code:str>/join", SpaceJoinHandler, name: "join"
      end
      path "/code", code_routes

      operating_hour_routes = Marten::Routing::Map.draw(:operating_hour) do
        path "/", OperatingHourCreateHandler, name: "create"
        path "/index", OperatingHourIndexHandler, name: "index"
        path "/<operating_hour_hashed_id:str>/update", OperatingHourUpdateHandler, name: "update"
        path "/<operating_hour_hashed_id:str>/delete", OperatingHourDeleteHandler, name: "delete"
      end
      path "/<space_hashed_id:str>/operating_hours", operating_hour_routes
    end

    path "/api/space", space_routes
  end
end
