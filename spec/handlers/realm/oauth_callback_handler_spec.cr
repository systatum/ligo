require "../../spec_helper"
require "../../support/multi_auth_spec_patch"

describe Ligo::OAuthCallbackHandler do
  after_each do
    MultiAuth::Engine.spec_reset!
  end

  it "returns 403 when state token is invalid" do
    realm = create_realm

    callback_path = Marten.routes.reverse(
      "realm_oauth_callback",
      realm_id: realm.id!,
      provider: "facebook"
    )
    response = Marten::Spec.client.get("#{callback_path}?code=test-code&state=invalid-state")

    response.status.should eq 403
    response.content.should eq({error: {messages: ["State token is invalid"]}}.to_json)
  end

  it "returns 400 when provider is unsupported" do
    realm = create_realm
    state = SignedToken.generate

    callback_path = Marten.routes.reverse(
      "realm_oauth_callback",
      realm_id: realm.id!,
      provider: "unsupported-provider"
    )
    response = Marten::Spec.client.get("#{callback_path}?code=test-code&state=#{state}")

    response.status.should eq 400
    JSON.parse(response.content)["error"]["messages"].as_a.first.as_s.should contain("Provider unsupported-provider not implemented")
  end

  it "returns jwt payload when callback succeeds" do
    realm = create_realm
    ensure_multi_auth_provider_config("facebook")
    MultiAuth::Engine.spec_set_user(build_multi_auth_user)

    state = SignedToken.generate
    callback_path = Marten.routes.reverse(
      "realm_oauth_callback",
      realm_id: realm.id!,
      provider: "facebook"
    )
    response = Marten::Spec.client.get("#{callback_path}?code=test-code&state=#{state}")

    response.status.should eq 200
    json = JSON.parse(response.content)
    json["email"].as_s.should eq "facebook-user@example.com"
    json["id"].as_s.should_not be_empty
    json["jwt_token"].as_s.should_not be_empty
  end

  it "returns jwt payload when callback succeeds and state param is missing" do
    realm = create_realm
    ensure_multi_auth_provider_config("facebook")
    MultiAuth::Engine.spec_set_user(build_multi_auth_user)

    callback_path = Marten.routes.reverse(
      "realm_oauth_callback",
      realm_id: realm.id!,
      provider: "facebook"
    )
    response = Marten::Spec.client.get("#{callback_path}?code=test-code")

    response.status.should eq 200
    json = JSON.parse(response.content)
    json["email"].as_s.should eq "facebook-user@example.com"
    json["id"].as_s.should_not be_empty
    json["jwt_token"].as_s.should_not be_empty
  end

  it "returns jwt payload when callback succeeds and state param is empty" do
    realm = create_realm
    ensure_multi_auth_provider_config("facebook")
    MultiAuth::Engine.spec_set_user(build_multi_auth_user)

    callback_path = Marten.routes.reverse(
      "realm_oauth_callback",
      realm_id: realm.id!,
      provider: "facebook"
    )
    response = Marten::Spec.client.get("#{callback_path}?code=test-code&state=")

    response.status.should eq 200
    json = JSON.parse(response.content)
    json["email"].as_s.should eq "facebook-user@example.com"
    json["id"].as_s.should_not be_empty
    json["jwt_token"].as_s.should_not be_empty
  end
end
