module Workaty::CandidateHelper
  @candidate : Workaty::Candidate?
  @schema : Workaty::CandidateSchema?

  def self.authorize_candidate_manipulation_request!(current_user : Auth::User?)
    return false unless current_user

    role = current_user.role!
    can = Auth::Role.at_least_chief_staff?(current_user) ||
          Auth::Role.hr_staff?(current_user)

    raise Auth::AuthorizationError.new unless can
  end

  def authorize_candidate_manipulation_request!
    Workaty::CandidateHelper.authorize_candidate_manipulation_request!(current_user)
  end

  private def candidate
    @candidate ||= Workaty::Candidate
      .filter_by_slug(params["candidate_slug"].to_s)
      .get!(organization_id: current_user!.organization_id)
  end

  private def schema
    @schema ||= Workaty::CandidateSchema.new(request.data, current_user!)
  end
end
