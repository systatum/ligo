require "../spec_helper"

# Reopen MultiAuth::Engine in specs so provider calls can be controlled
# deterministically without hitting real OAuth provider behavior.
class MultiAuth::Engine
  # Optional fake redirect URL returned by authorize_uri during tests.
  @@spec_authorize_uri : String? = nil
  # Optional fake user returned by user(...) during callback tests.
  @@spec_user : MultiAuth::User? = nil
  # Optional error raised by user(...) to simulate provider failures.
  @@spec_user_error : Exception? = nil
  # Captures the last scope passed to authorize_uri for assertions.
  @@spec_last_scope : String? = nil

  def self.spec_set_authorize_uri(uri : String?)
    @@spec_authorize_uri = uri
  end

  def self.spec_set_user(user : MultiAuth::User?)
    @@spec_user = user
  end

  def self.spec_set_user_error(error : Exception?)
    @@spec_user_error = error
  end

  def self.spec_last_scope : String?
    @@spec_last_scope
  end

  def self.spec_reset!
    @@spec_authorize_uri = nil
    @@spec_user = nil
    @@spec_user_error = nil
    @@spec_last_scope = nil
  end

  def authorize_uri(scope = nil)
    @@spec_last_scope = scope
    return @@spec_authorize_uri.not_nil! if @@spec_authorize_uri
    previous_def(scope)
  end

  def user(params : Enumerable({String, String})) : MultiAuth::User
    raise @@spec_user_error.not_nil! if @@spec_user_error
    return @@spec_user.not_nil! if @@spec_user
    previous_def(params)
  end
end

def ensure_multi_auth_provider_config(provider : String)
  return if MultiAuth.configuration[provider]?
  MultiAuth.config(provider, "spec-#{provider}-client-id", "spec-#{provider}-client-secret")
end

def build_multi_auth_user(
  provider : String = "FACEBOOK",
  uid : String = "facebook-id-123",
  name : String = "John Smith",
  email : String? = "facebook-user@example.com",
  first_name : String? = "John",
  last_name : String? = "Smith",
) : MultiAuth::User
  access_token = OAuth2::AccessToken::Bearer.from_json(%({"access_token":"dummy-token"}))

  MultiAuth::User.new(provider, uid, name, "{}", access_token).tap do |user|
    user.email = email
    user.first_name = first_name
    user.last_name = last_name
  end
end
