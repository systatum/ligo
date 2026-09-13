require "../spec_helper"

class JobStatusHandlerSpecFixtureJob
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "default"
  end

  def perform(value : String)
    value
  end
end

describe JobStatusHandler do
  context "when job id exists" do
    it "returns the job status right after it's queued" do
      job_id = JobStatusHandlerSpecFixtureJob.async.perform("hello").not_nil!

      response = Marten::Spec.client.get(Marten.routes.reverse("job_status", id: job_id))

      response.status.should eq 200
      payload = JSON.parse(response.content)
      payload["id"].as_s.should eq job_id
      payload["status"].as_s.should eq "queued"
      payload["job"].as_s.should eq "JobStatusHandlerSpecFixtureJob"
    ensure
      Sidekiq::Status.delete(job_id) if job_id
    end

    it "returns failed status with error details when the job has failed" do
      job_id = "test-failed-jid-#{Random::Secure.hex(8)}"
      now = Time.utc.to_unix

      Sidekiq::Status.write_field(job_id, {
        "status"        => "failed",
        "job"           => "JobStatusHandlerSpecFixtureJob",
        "started_at"    => now.to_s,
        "updated_at"    => now.to_s,
        "ended_at"      => now.to_s,
        "error_class"   => "RuntimeError",
        "error_message" => "something broke",
      })

      response = Marten::Spec.client.get(Marten.routes.reverse("job_status", id: job_id))

      response.status.should eq 200
      payload = JSON.parse(response.content)
      payload["status"].as_s.should eq "failed"
      payload["error"].as_s.should eq "something broke"
      payload["ended_at"].as_i64.should eq now
    ensure
      Sidekiq::Status.delete(job_id) if job_id
    end
  end

  context "when job id cannot be found" do
    it "returns 404" do
      response = Marten::Spec.client.get(Marten.routes.reverse("job_status", id: "missing-jid"))

      response.status.should eq 404
      JSON.parse(response.content)["error"]["messages"].as_a.map(&.as_s).should contain("Job not found")
    end
  end
end
