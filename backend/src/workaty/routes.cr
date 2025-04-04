module Workaty
  ROUTES = Marten::Routing::Map.draw do
    candidate_routes = Marten::Routing::Map.draw do
      path "", CandidateCreateHandler, name: "api_candidate_create"
      path "/<candidate_slug:str>", CandidateShowHandler, name: "api_candidate_show"
      path "/<candidate_slug:str>/update", CandidateUpdateHandler, name: "api_candidate_update"
      path "/<candidate_slug:str>/delete", CandidateDeleteHandler, name: "api_candidate_delete"

      degree_routes = Marten::Routing::Map.draw do
        path "", DegreeCreateHandler, name: "api_degree_create"
        path "/<degree_hashed_id:str>/update", DegreeUpdateHandler, name: "api_degree_update"
        path "/<degree_hashed_id:str>/delete", DegreeDeleteHandler, name: "api_degree_delete"
      end
      path "<candidate_slug:str>/degrees", degree_routes
    end

    path "/api/candidates", candidate_routes
  end
end
