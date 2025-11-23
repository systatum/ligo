class Workaty::TeamDivisionCreateHandler < RequestHandler
  include Workaty::TeamDivisionHelper

  protect_from_forgery false
  http_method_names :post

  def post
    authorize_team_division_manipulation_request!

    if schema.valid?
      team_division = Workaty::TeamDivision.new(schema.validated_data)
      team_division.organization = current_user!.organization
      team_division.save!
      json Workaty::TeamDivisionSerializer.serialize(team_division), status: 200
    else
      render_invalid_payload(schema)
    end
  end
end
