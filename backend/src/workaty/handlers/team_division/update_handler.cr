class Workaty::TeamDivisionUpdateHandler < RequestHandler
  include Workaty::TeamDivisionHelper

  protect_from_forgery false
  http_method_names :patch, :post

  def post
    patch
  end

  def patch
    authorize_team_division_manipulation_request!

    if schema.valid?
      team_division.update!(schema.validated_data)
      json Workaty::TeamDivisionSerializer.serialize(team_division), status: 200
    else
      render_invalid_payload(schema)
    end
  rescue e
    handle_error(e)
  end
end
