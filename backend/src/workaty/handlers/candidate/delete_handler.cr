class Workaty::CandidateDeleteHandler < RequestHandler
  include Workaty::CandidateHelper

  protect_from_forgery false
  http_method_names :delete

  def delete
    authorize_candidate_manipulation_request!

    candidate.soft_delete!
    json Workaty::CandidateSerializer.serialize(candidate), status: 200
  end
end
