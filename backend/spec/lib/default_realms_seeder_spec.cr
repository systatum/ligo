require "./spec_helper"

describe DefaultRealmsSeeder do
  describe "#seed!" do
    it "creates the default antrikan and workaty realms with correctly hashed keys" do
      result = DefaultRealmsSeeder.seed!

      result[:created].should eq 2
      result[:skipped].should eq 0
      result[:total].should eq 2

      DefaultRealmsSeeder::SEEDS.each do |seed|
        realm = Auth::Realm.get!(id: seed.id)
        realm.hashed_api_client_key.should eq Digest::SHA256.hexdigest(seed.api_client_key)
        realm.hashed_api_secret_key.should eq Digest::SHA256.hexdigest(seed.api_secret_key)
        realm.webhook_secret.should eq seed.webhook_secret
      end
    end

    it "is idempotent - running it again does not duplicate or error" do
      DefaultRealmsSeeder.seed!
      result = DefaultRealmsSeeder.seed!

      result[:created].should eq 0
      result[:skipped].should eq 2
      result[:total].should eq 2

      Auth::Realm.filter(id__in: ["antrikan", "workaty"]).count.should eq 2
    end

    it "refuses to run in production and creates nothing" do
      expect_raises(DefaultRealmsSeeder::ProductionNotAllowedError) do
        DefaultRealmsSeeder.seed!(env_id: "production")
      end

      Auth::Realm.filter(id__in: ["antrikan", "workaty"]).count.should eq 0
    end
  end
end
