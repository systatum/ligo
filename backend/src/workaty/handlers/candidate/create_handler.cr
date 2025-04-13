class Workaty::CandidateCreateHandler < RequestHandler
  include Workaty::CandidateHelper

  protect_from_forgery false
  http_method_names :post

  def post
    authorize_candidate_manipulation_request!

    if schema.valid?
      candidate = Workaty::Candidate.new(schema.validated_data)
      candidate.organization = current_user.organization
      candidate.save!
      json Workaty::CandidateSerializer.serialize(candidate), status: 200
    else
      render_invalid_payload
    end
  rescue e
    handle_error(e)
  end
end
