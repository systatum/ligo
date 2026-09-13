class JobStatusHandler < RequestHandler
  protect_from_forgery false
  http_method_names :get

  def get
    job_id = params["id"].to_s
    status_payload = Sidekiq::Status.fetch(job_id)

    return render_error 404, ["Job not found"] unless status_payload

    json status_payload, status: 200
  end
end
