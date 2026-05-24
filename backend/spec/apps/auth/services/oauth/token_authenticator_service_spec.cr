require "../../spec_helper"

def run_with_user(user : MultiAuth::User)
  ensure_multi_auth_provider_config("facebook")
  MultiAuth::Engine.spec_set_user(user)

  Auth::OAuthTokenAuthenticatorService.new(
    multi_auth: MultiAuth.make("facebook", "https://example.com/oauth/facebook/callback"),
    code: "test-auth-code"
  ).run
end

describe Auth::OAuthTokenAuthenticatorService do
  after_each do
    MultiAuth::Engine.spec_reset!
  end

  it "creates user and provider link on first facebook sign-in" do
    result = run_with_user(build_multi_auth_user)

    result.success?.should be_true
    user = result.data.not_nil!
    user.email.should eq("facebook-user@example.com")

    provider_link = Auth::Provider.filter(
      provider: Auth::ProviderType::FACEBOOK,
      provider_user_id: "facebook-id-123"
    ).first?
    provider_link.should_not be_nil
    provider_link.not_nil!.user!.id.should eq(user.id)
  end

  it "returns existing user matched by facebook id on repeat sign-in" do
    result1 = run_with_user(build_multi_auth_user)

    result1.success?.should be_true
    first_user_id = result1.data.not_nil!.id

    result2 = run_with_user(build_multi_auth_user)

    result2.success?.should be_true
    result2.data.not_nil!.id.should eq(first_user_id)
    Auth::Provider.filter(
      provider: Auth::ProviderType::FACEBOOK,
      provider_user_id: "facebook-id-123"
    ).count.should eq(1)
  end

  it "links provider to existing email-matched user" do
    existing_user = create_user(email: "existing@example.com")

    result = run_with_user(build_multi_auth_user(email: "existing@example.com"))

    result.success?.should be_true
    result.data.not_nil!.id.should eq(existing_user.id)

    provider_link = Auth::Provider.filter(
      provider: Auth::ProviderType::FACEBOOK,
      provider_user_id: "facebook-id-123"
    ).first?
    provider_link.should_not be_nil
    provider_link.not_nil!.user!.id.should eq(existing_user.id)
  end

  it "creates user and provider link when facebook profile does not include email" do
    result = run_with_user(build_multi_auth_user(email: nil, name: "No Email", first_name: "No", last_name: "Email"))

    result.success?.should be_true
    user = result.data.not_nil!
    user.email.should eq("facebook-facebook-id-123@oauth.invalid")
    user.first_name.should eq("No")
    user.last_name.should eq("Email")
    user.iam_identifier_primary.should_not be_nil
    user.iam_identifier_primary.not_nil!.should_not be_empty

    provider_link = Auth::Provider.filter(
      provider: Auth::ProviderType::FACEBOOK,
      provider_user_id: "facebook-id-123"
    ).first?
    provider_link.should_not be_nil
    provider_link.not_nil!.user!.id.should eq(user.id)
  end

  it "returns existing provider-linked user even when profile email is missing" do
    user = create_user(email: "linked-user@example.com")
    Auth::Provider.create!(
      user: user,
      provider: Auth::ProviderType::FACEBOOK.value.to_i64,
      provider_user_id: "facebook-id-123"
    )

    result = run_with_user(build_multi_auth_user(email: nil, name: "No Email", first_name: "No", last_name: "Email"))

    result.success?.should be_true
    result.data.not_nil!.id.should eq(user.id)
  end
end
