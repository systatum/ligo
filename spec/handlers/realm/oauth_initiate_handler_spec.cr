require "../../spec_helper"
require "../../support/multi_auth_spec_patch"

describe Ligo::OAuthInitiateHandler do
  after_each do
    MultiAuth::Engine.spec_reset!
  end

  it "redirects to provider authorize uri with mapped scope" do
    realm = create_realm
    ensure_multi_auth_provider_config("facebook")
    MultiAuth::Engine.spec_set_authorize_uri("https://example-oauth-provider.test/authorize")

    response = Marten::Spec.client.get(
      Marten.routes.reverse("realm_oauth_initiate",
        realm_id: realm.id!,
        provider: "facebook"
      )
    )

    response.status.should eq 302
    response.headers["Location"].should eq "https://example-oauth-provider.test/authorize"
    MultiAuth::Engine.spec_last_scope.should eq "email"
  end

  it "returns 400 when provider is unsupported" do
    realm = create_realm

    response = Marten::Spec.client.get(
      Marten.routes.reverse("realm_oauth_initiate",
        realm_id: realm.id!,
        provider: "unsupported-provider"
      )
    )

    response.status.should eq 400
    JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Provider unsupported-provider not implemented")
  end
end
