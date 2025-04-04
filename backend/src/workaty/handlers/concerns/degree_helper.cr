module Workaty::DegreeHelper
  @schema : Workaty::DegreeSchema?
  @candidate : Workaty::Candidate?
  @degree : Workaty::Degree?

  def authorize_degree_manipulation_request!
    Workaty::CandidateHelper.authorize_candidate_manipulation_request!(current_user)

    is_from_same_org = candidate.organization_id == current_user.organization_id
    raise Auth::AuthorizationError.new unless is_from_same_org
  end

  private def candidate
    @candidate ||= Workaty::Candidate
      .filter_by_slug(params["candidate_slug"].to_s)
      .get!(organization_id: current_user.organization_id)
  end

  private def degree
    @degree ||= Workaty::Degree
      .filter_by_hashed_id(params["degree_hashed_id"].to_s)
      .get!(candidate_id: candidate.id!)
  end

  private def schema
    @schema ||= Workaty::DegreeSchema.new(request.data)
  end
end
