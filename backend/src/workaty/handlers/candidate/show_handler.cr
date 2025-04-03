class Workaty::CandidateShowHandler < RequestHandler
  include Workaty::CandidateHelper

  http_method_names :get

  def get
    json Workaty::CandidateSerializer.serialize(candidate), status: 200
  end
end
