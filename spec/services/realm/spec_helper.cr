require "../../spec_helper"
require "../../support/multi_auth_spec_patch"

# given a fake OAuth profile (user) and a realm, simulate a full
# Facebook login attempt and return whatever the authenticator service produces
def run_with_user(user : MultiAuth::User, realm : Ligo::Realm)
  ensure_multi_auth_provider_config("facebook")
  MultiAuth::Engine.spec_set_user(user)

  Ligo::OAuthTokenAuthenticatorService.new(
    realm: realm,
    multi_auth: MultiAuth.make("facebook", "https://example.com/oauth/facebook/callback"),
    code: "test-auth-code"
  ).run
end
