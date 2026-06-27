require "./user_factory"

def create_realm(
  ack_semantic : AcknowledgeSemantic = AcknowledgeSemantic::NONE,
  app_name : String = "TestApp",
  app_id : String = "fb_test_id",
  app_secret : String = "fb_test_secret",
  registration_redirection_uri : String = "https://testapp.example.com/auth/callback",
  registration_ack_uri : String = "https://testapp.example.com/webhooks/iam",
  max_ack_retry_attempts : Int32? = nil,
) : Auth::Realm
  realm = Auth::Realm.new
  realm.id = "test#{Random.rand(10_000..99_999)}"
  realm.app_name = app_name
  realm.hashed_api_secret_key = Digest::SHA256.hexdigest("sk_test_raw_#{Random.rand}")
  realm.hashed_api_client_key = Digest::SHA256.hexdigest("ck_test_raw_#{Random.rand}")
  realm.webhook_secret = Random::Secure.urlsafe_base64(11)
  realm.ack_semantic = ack_semantic
  realm.app_id = app_id
  realm.app_secret = app_secret
  realm.registration_redirection_uri = registration_redirection_uri
  realm.registration_ack_uri = registration_ack_uri
  realm.max_ack_retry_attempts = max_ack_retry_attempts
  realm.save!

  realm
end
