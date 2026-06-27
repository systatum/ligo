require "./spec_helper"

describe Auth::RealmCreateHandler do
  it "returns generated credentials" do
    response = Marten::Spec.client.post(
      Marten.routes.reverse("auth:realm:create"),
      data: {
        "app_name"                     => "BilQuran",
        "app_id"                       => "fb_app_id_123",
        "app_secret"                   => "fb_app_secret_abc",
        "ack_semantic"                 => "mutual",
        "max_ack_retry_attempts"       => 50,
        "registration_redirection_uri" => "https://bilquran.com/auth/callback",
        "registration_ack_uri"         => "https://bilquran.com/webhooks/iam",
      }
    )

    response.status.should eq 200
    body = JSON.parse(response.content)

    # credentials are present in response
    body["api_secret_key"].should_not be_nil
    body["api_client_key"].should_not be_nil
    body["webhook_secret"].should_not be_nil

    # keys look like raw urlsafe_base64 (not hashed)
    body["api_secret_key"].as_s.size.should eq 60
    body["api_client_key"].as_s.size.should eq 60
    body["webhook_secret"].as_s.size.should eq 15

    # realm is persisted
    realm = Auth::Realm.last!
    realm.app_name.should eq "BilQuran"
    realm.ack_semantic.should eq AcknowledgeSemantic::MUTUAL
    realm.registration_redirection_uri.should eq "https://bilquran.com/auth/callback"
    realm.registration_ack_uri.should eq "https://bilquran.com/webhooks/iam"

    # stored keys are hashed, not equal to raw
    realm.hashed_api_secret_key.should_not eq body["api_secret_key"].as_s
    realm.hashed_api_client_key.should_not eq body["api_client_key"].as_s

    # stored hash matches digest of returned raw key
    Digest::SHA256.hexdigest(body["api_secret_key"].as_s).should eq realm.hashed_api_secret_key
    Digest::SHA256.hexdigest(body["api_client_key"].as_s).should eq realm.hashed_api_client_key
  end

  it "returns 422 when required fields are missing" do
    response = Marten::Spec.client.post(
      Marten.routes.reverse("auth:realm:create"),
      data: {"app_name" => ""}
    )

    response.status.should eq 422
  end
end
