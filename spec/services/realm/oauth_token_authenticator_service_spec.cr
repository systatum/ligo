require "./spec_helper"

describe Ligo::OAuthTokenAuthenticatorService do
  after_each do
    MultiAuth::Engine.spec_reset!
  end

  it "creates user and realm_user link on first facebook sign-in" do
    realm = create_realm
    result = run_with_user(build_multi_auth_user, realm)

    result.success?.should be_true
    user = result.data.not_nil!
    user.email.should eq("facebook-user@example.com")

    realm_user = Ligo::RealmUser.filter(
      provider: ProviderType::FACEBOOK,
      provider_user_id: "facebook-id-123"
    ).first?
    realm_user.should_not be_nil
    realm_user.not_nil!.user!.id.should eq(user.id)
  end

  it "returns existing user matched by facebook id on repeat sign-in" do
    realm = create_realm
    result1 = run_with_user(build_multi_auth_user, realm)

    result1.success?.should be_true
    first_user_id = result1.data.not_nil!.id

    result2 = run_with_user(build_multi_auth_user, realm)

    result2.success?.should be_true
    result2.data.not_nil!.id.should eq(first_user_id)
    Ligo::RealmUser.filter(
      provider: ProviderType::FACEBOOK,
      provider_user_id: "facebook-id-123"
    ).count.should eq(1)
  end

  it "links realm_user to existing email-matched user" do
    realm = create_realm
    existing_user = create_user(email: "existing@example.com")

    result = run_with_user(build_multi_auth_user(email: "existing@example.com"), realm)

    result.success?.should be_true
    result.data.not_nil!.id.should eq(existing_user.id)

    realm_user = Ligo::RealmUser.filter(
      provider: ProviderType::FACEBOOK,
      provider_user_id: "facebook-id-123"
    ).first?
    realm_user.should_not be_nil
    realm_user.not_nil!.user!.id.should eq(existing_user.id)
  end

  it "creates user and realm_user link when facebook profile does not include email" do
    realm = create_realm
    result = run_with_user(build_multi_auth_user(
      email: nil,
      name: "No Email",
      first_name: "No",
      last_name: "Email"
    ), realm)

    result.success?.should be_true
    user = result.data.not_nil!
    user.email.should eq("facebook-facebook-id-123@oauth.invalid")
    user.first_name.should eq("No")
    user.last_name.should eq("Email")
    user.iam_identifier_primary.should_not be_nil
    user.iam_identifier_primary.not_nil!.should_not be_empty

    realm_user = Ligo::RealmUser.filter(
      provider: ProviderType::FACEBOOK,
      provider_user_id: "facebook-id-123"
    ).first?
    realm_user.should_not be_nil
    realm_user.not_nil!.user!.id.should eq(user.id)
  end

  it "returns existing realm_user-linked user even when profile email is missing" do
    realm = create_realm
    user = create_user(email: "linked-user@example.com")
    Ligo::RealmUser.create!(
      user: user,
      provider: ProviderType::FACEBOOK.value.to_i64,
      provider_user_id: "facebook-id-123",
      realm: realm
    )

    result = run_with_user(build_multi_auth_user(
      email: nil,
      name: "No Email",
      first_name: "No",
      last_name: "Email"
    ), realm)

    result.success?.should be_true
    result.data.not_nil!.id.should eq(user.id)
  end

  describe "#ack_semantic" do
    context "when NONE" do
      it "acknowledges the realm_user immediately and skips the webhook content" do
        realm = create_realm(ack_semantic: AcknowledgeSemantic::NONE)
        result = run_with_user(build_multi_auth_user, realm)

        result.success?.should be_true

        realm_user = Ligo::RealmUser.filter(
          provider: ProviderType::FACEBOOK,
          provider_user_id: "facebook-id-123"
        ).first!
        realm_user.acked_at.should_not be_nil
      end
    end

    context "when MUTUAL" do
      it "leaves the realm_user unacked and creates webhook content" do
        realm = create_realm(ack_semantic: AcknowledgeSemantic::MUTUAL)
        result = run_with_user(build_multi_auth_user, realm)

        result.success?.should be_true

        realm_user = Ligo::RealmUser.filter(
          provider: ProviderType::FACEBOOK,
          provider_user_id: "facebook-id-123"
        ).first!
        realm_user.acked_at.should be_nil
        realm_user.registration_webhook_content_id.should_not be_nil
      end
    end

    context "when OPTIONAL" do
      it "leaves the realm_user unacked and creates webhook content" do
        realm = create_realm(ack_semantic: AcknowledgeSemantic::OPTIONAL)
        result = run_with_user(build_multi_auth_user, realm)

        result.success?.should be_true

        realm_user = Ligo::RealmUser.filter(
          provider: ProviderType::FACEBOOK,
          provider_user_id: "facebook-id-123"
        ).first!
        realm_user.acked_at.should be_nil
        realm_user.registration_webhook_content_id.should_not be_nil
      end
    end
  end

  context "when the same Facebook user authenticates into different realms" do
    it "creates a separate RealmUser record per realm" do
      realm_a = create_realm(app_name: "BilQuran", ack_semantic: AcknowledgeSemantic::NONE)
      realm_b = create_realm(app_name: "Antrikan", ack_semantic: AcknowledgeSemantic::NONE)

      ensure_multi_auth_provider_config("facebook")

      MultiAuth::Engine.spec_set_user(build_multi_auth_user(uid: "same-fb-uid"))
      Ligo::OAuthTokenAuthenticatorService.new(
        realm: realm_a,
        multi_auth: MultiAuth.make("facebook", "https://example.com/oauth/facebook/callback"),
        code: "code-a"
      ).run

      MultiAuth::Engine.spec_set_user(build_multi_auth_user(uid: "same-fb-uid"))
      Ligo::OAuthTokenAuthenticatorService.new(
        realm: realm_b,
        multi_auth: MultiAuth.make("facebook", "https://example.com/oauth/facebook/callback"),
        code: "code-b"
      ).run

      user = Ligo::User.filter(email: "facebook-user@example.com").first!
      realm_users = Ligo::RealmUser.filter(user: user)
      realm_users.count.should eq 2
      realm_users.map { |ru| ru.realm.not_nil!.id! }.should contain(realm_a.id!)
      realm_users.map { |ru| ru.realm.not_nil!.id! }.should contain(realm_b.id!)
    end

    context "when the same Facebook user authenticates into the same realm again" do
      it "resolves to the existing RealmUser instead of creating a duplicate" do
        realm = create_realm(app_name: "BilQuran", ack_semantic: AcknowledgeSemantic::NONE)

        ensure_multi_auth_provider_config("facebook")

        MultiAuth::Engine.spec_set_user(build_multi_auth_user(uid: "same-fb-uid"))
        Ligo::OAuthTokenAuthenticatorService.new(
          realm: realm,
          multi_auth: MultiAuth.make("facebook", "https://example.com/oauth/facebook/callback"),
          code: "code-a"
        ).run

        MultiAuth::Engine.spec_set_user(build_multi_auth_user(uid: "same-fb-uid"))
        result = Ligo::OAuthTokenAuthenticatorService.new(
          realm: realm,
          multi_auth: MultiAuth.make("facebook", "https://example.com/oauth/facebook/callback"),
          code: "code-b"
        ).run

        result.success?.should be_true
        Ligo::RealmUser.filter(
          provider: ProviderType::FACEBOOK,
          provider_user_id: "same-fb-uid",
          realm: realm
        ).count.should eq 1
      end
    end
  end

  context "when the OAuth provider raises an error" do
    it "returns a failure result" do
      realm = create_realm
      ensure_multi_auth_provider_config("facebook")
      MultiAuth::Engine.spec_set_user_error(Exception.new("Provider rejected the code"))

      result = Ligo::OAuthTokenAuthenticatorService.new(
        realm: realm,
        multi_auth: MultiAuth.make("facebook", "https://example.com/oauth/facebook/callback"),
        code: "invalid-code"
      ).run

      result.success?.should be_false
    end
  end
end
