require "./spec_helper"

describe Auth::OAuthInitiateHandler do
  original_app_mode = ENV["LIGO_APP_MODE"]

  after_each do
    ENV["LIGO_APP_MODE"] = original_app_mode
    MultiAuth::Engine.spec_reset!
  end

  it "returns 404 when app mode is not iam" do
    ENV["LIGO_APP_MODE"] = "workaty"

    response = Marten::Spec.client.get(
      Marten.routes.reverse("auth:api_oauth_initiate", provider: "facebook")
    )

    response.status.should eq 404
  end

  it "redirects to provider authorize uri with mapped scope" do
    ensure_multi_auth_provider_config("facebook")
    MultiAuth::Engine.spec_set_authorize_uri("https://example-oauth-provider.test/authorize")

    response = Marten::Spec.client.get(
      Marten.routes.reverse("auth:api_oauth_initiate", provider: "facebook")
    )

    response.status.should eq 302
    response.headers["Location"].should eq "https://example-oauth-provider.test/authorize"
    MultiAuth::Engine.spec_last_scope.should eq "email"
  end

  it "returns 400 when provider is unsupported" do
    response = Marten::Spec.client.get(
      Marten.routes.reverse("auth:api_oauth_initiate", provider: "unsupported-provider")
    )

    response.status.should eq 400
    JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Provider unsupported-provider not implemented")
  end
end
