require "./spec_helper"

describe Auth::RequestEmailVerificationHandler do
  original_app_mode = ENV["LIGO_APP_MODE"]

  after_each do
    ENV["LIGO_APP_MODE"] = original_app_mode
  end

  context "when app mode is not iam" do
    it "returns 404" do
      ENV["LIGO_APP_MODE"] = "workaty"

      path = Marten.routes.reverse("auth:api_request_email_verification")
      response = Marten::Spec.client.get("#{path}?email=test@example.com")

      response.status.should eq 404
    end
  end

  context "when email param is missing" do
    it "returns 400" do
      path = Marten.routes.reverse("auth:api_request_email_verification")
      response = Marten::Spec.client.get(path)

      response.status.should eq 400
      JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Email is required")
    end
  end

  context "when email is provided" do
    it "enqueues a verification job and returns 200" do
      expect_jobs(Auth::User::EmailVerificationSendJob, 1, queue: "mailers") do
        path = Marten.routes.reverse("auth:api_request_email_verification")
        response = Marten::Spec.client.get("#{path}?email=test@example.com")

        response.status.should eq 200
        response.content.should eq "{}"
      end
    end

    it "passes redirectionUri to the job" do
      expect_jobs(Auth::User::EmailVerificationSendJob, 1, queue: "mailers") do
        path = Marten.routes.reverse("auth:api_request_email_verification")
        response = Marten::Spec.client.get("#{path}?email=test@example.com&redirectionUri=https://example.com/callback")

        response.status.should eq 200
      end
    end

    it "passes expiredAt to the job" do
      future = (Time.utc + 3600.seconds).to_s("%Y-%m-%dT%H:%M:%S%z")

      expect_jobs(Auth::User::EmailVerificationSendJob, 1, queue: "mailers") do
        path = Marten.routes.reverse("auth:api_request_email_verification")
        response = Marten::Spec.client.get("#{path}?email=test@example.com&expiredAt=#{future}")

        response.status.should eq 200
      end
    end
  end
end
