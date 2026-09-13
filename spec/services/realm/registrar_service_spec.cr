require "./spec_helper"

describe Ligo::Realm::RegistrarService do
  it "creates a realm with all provided fields" do
    result = Ligo::Realm::RegistrarService.new(
      Marten::HTTP::Params::Data{
        "app_name"                     => ["BilQuran"],
        "app_id"                       => ["fb_app_id_123"],
        "app_secret"                   => ["fb_app_secret_abc"],
        "ack_semantic"                 => ["mutual"],
        "max_ack_retry_attempts"       => ["25"],
        "registration_redirection_uri" => ["https://bilquran.com/auth/callback"],
        "registration_ack_uri"         => ["https://bilquran.com/webhooks/iam"],
      }
    ).run

    result.success?.should be_true

    realm = Ligo::Realm.last!
    realm.app_name.should eq "BilQuran"
    realm.ack_semantic.should eq AcknowledgeSemantic::MUTUAL
    realm.max_ack_retry_attempts.should eq 25
    realm.registration_redirection_uri.should eq "https://bilquran.com/auth/callback"
    realm.registration_ack_uri.should eq "https://bilquran.com/webhooks/iam"
  end

  it "creates a realm without optional URI fields" do
    result = Ligo::Realm::RegistrarService.new(
      Marten::HTTP::Params::Data{
        "app_name"     => ["MinimalApp"],
        "app_id"       => ["fb_id"],
        "app_secret"   => ["fb_secret"],
        "ack_semantic" => ["none"],
      }
    ).run

    result.success?.should be_true

    realm = Ligo::Realm.last!
    realm.app_name.should eq "MinimalApp"
    realm.ack_semantic.should eq AcknowledgeSemantic::NONE
  end

  it "defaults max_ack_retry_attempts to 50 when not provided" do
    result = Ligo::Realm::RegistrarService.new(
      Marten::HTTP::Params::Data{
        "app_name"     => ["DefaultRetryApp"],
        "app_id"       => ["fb_id"],
        "app_secret"   => ["fb_secret"],
        "ack_semantic" => ["mutual"],
      }
    ).run

    result.success?.should be_true

    realm = Ligo::Realm.last!
    realm.max_ack_retry_attempts.should eq 50
  end

  it "stores SHA-256 hashed keys, not raw values" do
    result = Ligo::Realm::RegistrarService.new(
      Marten::HTTP::Params::Data{
        "app_name"     => ["HashTest"],
        "app_id"       => ["fb_id"],
        "app_secret"   => ["fb_secret"],
        "ack_semantic" => ["none"],
      }
    ).run

    result.success?.should be_true
    credentials = result.data.not_nil!
    realm = Ligo::Realm.last!

    realm.hashed_api_secret_key.should_not eq credentials[:api_secret_key]
    realm.hashed_api_client_key.should_not eq credentials[:api_client_key]
    Digest::SHA256.hexdigest(credentials[:api_secret_key]).should eq realm.hashed_api_secret_key
    Digest::SHA256.hexdigest(credentials[:api_client_key]).should eq realm.hashed_api_client_key
  end

  it "returns raw credentials of expected lengths" do
    result = Ligo::Realm::RegistrarService.new(
      Marten::HTTP::Params::Data{
        "app_name"     => ["CredLengths"],
        "app_id"       => ["fb_id"],
        "app_secret"   => ["fb_secret"],
        "ack_semantic" => ["none"],
      }
    ).run

    result.success?.should be_true
    credentials = result.data.not_nil!

    credentials[:api_secret_key].size.should eq 60
    credentials[:api_client_key].size.should eq 60
    credentials[:webhook_secret].size.should eq 15
  end

  it "returns failure when required fields are missing" do
    result = Ligo::Realm::RegistrarService.new(
      Marten::HTTP::Params::Data{"app_name" => [""]}
    ).run

    result.success?.should be_false
  end
end
