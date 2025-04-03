class Workaty::CandidateDeleteHandler < RequestHandler
  include Workaty::CandidateHelper

  http_method_names :delete

  def delete
    authorize_candidate_manipulation_request!

    candidate.soft_delete!
    json Workaty::CandidateSerializer.serialize(candidate), status: 200
  rescue e
    handle_error(e)
  end
end
