class Workaty::TeamDivisionDeleteHandler < RequestHandler
  include TeamDivisionHelper

  protect_from_forgery false
  http_method_names :delete

  def delete
    authorize_team_division_manipulation_request!

    team_division.soft_delete!
    json Workaty::TeamDivisionSerializer.serialize(team_division), status: 200
  end
end
