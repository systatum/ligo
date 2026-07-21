require "openssl"

# Seeds fixed, publicly-known dev-only Realms for Antrikan and Workaty so a
# fresh local checkout can exercise sign-up/webhook flows without first
# hitting POST /api/realm/create by hand. Never run in production - the
# credentials below are committed to source control and therefore public.
module DefaultRealmsSeeder
  extend self

  class RealmSeed
    property id : String
    property app_name : String
    property api_client_key : String
    property api_secret_key : String
    property webhook_secret : String
    property ack_semantic : AcknowledgeSemantic

    def initialize(
      @id : String,
      @app_name : String,
      @api_client_key : String,
      @api_secret_key : String,
      @webhook_secret : String,
      @ack_semantic : AcknowledgeSemantic = AcknowledgeSemantic::NONE,
    )
    end
  end

  class ProductionNotAllowedError < Exception
  end

  SEEDS = [
    RealmSeed.new(
      id: "antrikan",
      app_name: "Antrikan (dev)",
      api_client_key: "antrikan_dev_client_key",
      api_secret_key: "antrikan_dev_secret_key",
      webhook_secret: "antrikan_dev_wh",
    ),
    RealmSeed.new(
      id: "workaty",
      app_name: "Workaty (dev)",
      api_client_key: "workaty_dev_client_key",
      api_secret_key: "workaty_dev_secret_key",
      webhook_secret: "workaty_dev_whk",
    ),
  ]

  def seed!(env_id : String = Marten.env.id) : NamedTuple(created: Int32, skipped: Int32, total: Int32)
    if env_id == "production"
      raise ProductionNotAllowedError.new(
        "DefaultRealmsSeeder must not run in production - it seeds fixed, publicly-known dev credentials."
      )
    end

    created_count = 0
    skipped_count = 0

    SEEDS.each do |seed|
      if Auth::Realm.filter(id: seed.id).exists?
        skipped_count += 1
      else
        create_realm(seed)
        created_count += 1
      end
    end

    {created: created_count, skipped: skipped_count, total: SEEDS.size}
  end

  private def create_realm(seed : RealmSeed)
    realm = Auth::Realm.new
    realm.id = seed.id
    realm.app_name = seed.app_name
    realm.hashed_api_client_key = Digest::SHA256.hexdigest(seed.api_client_key)
    realm.hashed_api_secret_key = Digest::SHA256.hexdigest(seed.api_secret_key)
    realm.webhook_secret = seed.webhook_secret
    realm.ack_semantic = seed.ack_semantic
    realm.app_id = "#{seed.id}_dev_fb_app_id"
    realm.app_secret = "#{seed.id}_dev_fb_app_secret"
    realm.save!
  end
end
