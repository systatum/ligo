require "../spec_helper"

describe Ligo::RequestEmailVerificationHandler do
  context "when email param is missing" do
    it "returns 400" do
      path = Marten.routes.reverse("request_email_verification")
      response = Marten::Spec.client.get(path)

      response.status.should eq 400
      JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Email is required")
    end
  end

  context "when email is provided" do
    it "enqueues a verification job and returns 200" do
      expect_jobs(Ligo::User::EmailVerificationSendJob, 1, queue: "mailers") do
        path = Marten.routes.reverse("request_email_verification")
        response = Marten::Spec.client.get("#{path}?email=test@example.com")

        response.status.should eq 200
        response.content.should eq "{}"
      end
    end

    it "passes redirectionUri to the job" do
      expect_jobs(Ligo::User::EmailVerificationSendJob, 1, queue: "mailers") do
        path = Marten.routes.reverse("request_email_verification")
        response = Marten::Spec.client.get("#{path}?email=test@example.com&redirectionUri=https://example.com/callback")

        response.status.should eq 200
      end
    end

    it "passes expiredAt to the job" do
      future = (Time.utc + 3600.seconds).to_s("%Y-%m-%dT%H:%M:%S%z")

      expect_jobs(Ligo::User::EmailVerificationSendJob, 1, queue: "mailers") do
        path = Marten.routes.reverse("request_email_verification")
        response = Marten::Spec.client.get("#{path}?email=test@example.com&expiredAt=#{future}")

        response.status.should eq 200
      end
    end
  end
end
