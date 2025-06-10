module Workaty::TeamDivisionHelper
  @team_division : Workaty::TeamDivision?
  @schema : Workaty::TeamDivisionSchema?

  def self.authorize_team_division_manipulation_request!(current_user)
    Workaty::CandidateHelper.authorize_candidate_manipulation_request!(current_user)
  end

  def authorize_team_division_manipulation_request!
    Workaty::TeamDivisionHelper.authorize_team_division_manipulation_request!(current_user)
  end

  private def team_division
    @team_division ||= Workaty::TeamDivision
      .filter_by_hashed_id(params["team_division_hashed_id"].to_s)
      .get!(organization_id: current_user!.organization_id)
  end

  private def schema
    @schema ||= Workaty::TeamDivisionSchema.new(request.data, current_user!)
  end
end
