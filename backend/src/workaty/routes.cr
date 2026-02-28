module Workaty
  ROUTES = Marten::Routing::Map.draw do
    candidate_routes = Marten::Routing::Map.draw(:candidate) do
      path "", CandidateCreateHandler, name: "create"
      path "/<candidate_slug:str>", CandidateShowHandler, name: "show"
      path "/<candidate_slug:str>/update", CandidateUpdateHandler, name: "update"
      path "/<candidate_slug:str>/delete", CandidateDeleteHandler, name: "delete"

      degree_routes = Marten::Routing::Map.draw(:degree) do
        path "", DegreeCreateHandler, name: "create"
        path "/<degree_hashed_id:str>/update", DegreeUpdateHandler, name: "update"
        path "/<degree_hashed_id:str>/delete", DegreeDeleteHandler, name: "delete"
      end
      path "<candidate_slug:str>/degrees", degree_routes
    end

    team_division_routes = Marten::Routing::Map.draw(:team_division) do
      path "/", TeamDivisionCreateHandler, name: "create"
      path "/<team_division_hashed_id:str>/update", TeamDivisionUpdateHandler, name: "update"
      path "/<team_division_hashed_id:str>/delete", TeamDivisionDeleteHandler, name: "delete"
    end

    employee_routes = Marten::Routing::Map.draw(:employee) do
      path "/", EmployeeCreateHandler, name: "create"
      path "/index", EmployeeIndexHandler, name: "index"
      path "/<employee_slug:str>/update", EmployeeUpdateHandler, name: "update"
      path "/<employee_slug:str>/delete", EmployeeDeleteHandler, name: "delete"
    end

    email_routes = Marten::Routing::Map.draw(:email) do
      template_routes = Marten::Routing::Map.draw(:template) do
        path "/", EmailTemplateCreateHandler, name: "create"
        path "/index", EmailTemplateIndexHandler, name: "index"
        path "/<template_hashed_id:str>", EmailTemplateShowHandler, name: "show"
        path "/<template_hashed_id:str>/update", EmailTemplateUpdateHandler, name: "update"
        path "/<template_hashed_id:str>/delete", EmailTemplateDeleteHandler, name: "delete"
      end
      path "/template", template_routes
    end

    path "/api/candidate", candidate_routes
    path "/api/team_division", team_division_routes
    path "/api/employee", employee_routes
    path "/api/email", email_routes
  end
end
