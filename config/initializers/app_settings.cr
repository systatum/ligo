class AppSettings
  include TypedEnvConfig

  field ligo_salt_for_id_concealer : String, default: ""
  field ligo_password_reset_token_expiry_minutes : Int32, default: 5
  field ligo_email_verification_token_expiry_minutes : Int32, default: 60
  field ligo_app_cors_whitelist : String, default: ""
  field ligo_app_cors_ok_headers : String, default: ""

  field ligo_redis_host : String, default: "127.0.0.1"
  field ligo_redis_port : Int32, default: 6379
  field ligo_redis_password : String, default: ""
  field ligo_redis_database_number : Int32, default: 0

  @@instance : AppSettings?

  def self.instance
    @@instance ||= begin
      config = AppSettings.load_from_yaml_file!("./app_settings.yml", Marten.env.id)
      config.load_from_env_file
      config.load_from_env!
      config
    end
  end
end

AppSettings.instance
