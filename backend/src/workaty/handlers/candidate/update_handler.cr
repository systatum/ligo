class Workaty::CandidateUpdateHandler < RequestHandler
  include Workaty::CandidateHelper

  http_method_names :patch, :post

  def post
    patch
  end

  def patch
    authorize_candidate_manipulation_request!

    if schema.valid?
      candidate.update!(schema.validated_data)
      json Workaty::CandidateSerializer.serialize(candidate), status: 200
    else
      render_invalid_payload
    end
  rescue e
    handle_error(e)
  end
end
