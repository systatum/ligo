require "yaml"

require "./app_info"

class AppSettings
  include TypedEnvConfig

  field ligo_app_cors_whitelist : String, default: ""
  field ligo_app_cors_ok_headers : String, default: ""
  field ligo_app_salt_for_id_concealer : String, default: ""
  field ligo_app_base_url : String, default: "http://localhost:8000" # The url for a ligo app (e.g https://workaty.com)
  field ligo_app_password_reset_token_expiry_minutes : Int32, default: 5
  field ligo_app_email_verification_token_expiry_minutes : Int32, default: 60
  field ligo_app_mode : String, default: ""

  field ligo_database_host : String, default: "", envvar: "LIGO_DB_HOST"
  field ligo_database_port : Int32, default: 0, envvar: "LIGO_DB_PORT"
  field ligo_database_name : String, default: "", envvar: "LIGO_DB_NAME"
  field ligo_database_user : String, default: "", envvar: "LIGO_DB_USERNAME"
  field ligo_database_password : String, default: "", envvar: "LIGO_DB_PASSWORD"

  field ligo_mailer_smtp_host : String, default: ""
  field ligo_mailer_smtp_port : Int32, default: 0
  field ligo_mailer_smtp_domain : String, default: ""
  field ligo_mailer_smtp_username : String, default: ""
  field ligo_mailer_smtp_password : String, default: ""
  field ligo_mailer_smtp_use_auth : Bool, default: false
  field ligo_mailer_smtp_use_smtps : Bool, default: false
  field ligo_mailer_smtp_use_starttls : Bool, default: false

  field ligo_mailer_from_email : String, default: "noreply@workaty.com"
  field ligo_mailer_from_name : String, default: "Workaty"
  field ligo_mailer_company_name : String, default: "@Workaty"
  field ligo_mailer_company_address : String, default: "Hakuraku Hills 15-34 Yokohama Japan"
  field ligo_mailer_company_image : String, default: "https://workaty.com/_next/image?url=%2F_next%2Fstatic%2Fmedia%2Fworkaty%20icon%20only_2048.664f571f.png&w=100&q=100"

  field ligo_s3_region : String, default: "us-east-1"
  field ligo_s3_bucket : String, default: ""
  field ligo_s3_access_key : String, default: ""
  field ligo_s3_secret_key : String, default: ""
  field ligo_s3_endpoint : String, default: ""
  field ligo_s3_force_path_style : Bool, default: false

  field ligo_redis_host : String, default: "127.0.0.1"
  field ligo_redis_port : Int32, default: 6379
  field ligo_redis_password : String, default: ""
  field ligo_redis_database_number : Int32, default: 0

  field ligo_sidekiq_redis_host : String, default: "127.0.0.1"
  field ligo_sidekiq_redis_port : Int32, default: 6379
  field ligo_sidekiq_redis_password : String, default: ""
  field ligo_sidekiq_redis_database_number : Int32, default: 0
  field ligo_sidekiq_dashboard_session_secret : String, default: "" # A secret key used to secure the Sidekiq dashboard session
  field ligo_sidekiq_job_status_expiry : Int32, default: 86_400     # The expiration time in seconds for the job status

  field ligo_facebook_app_id : String, default: ""
  field ligo_facebook_app_secret : String, default: ""
  field ligo_webhook_secret : String, default: ""

  @@instance : AppSettings?

  def self.instance
    @@instance ||= begin
      config = AppSettings.load_from_yaml_file!("./app_settings.yml", Marten.env.id)
      config.load_from_env_file
      config.load_from_env!
      config
    end
  end

  def self.app_mode : String
    mode = ENV["LIGO_APP_MODE"]?.presence || self.instance.ligo_app_mode
    valid_modes = AppInfo.all.keys
    unless mode && valid_modes.includes?(mode)
      raise Exception.new("LIGO_APP_MODE must be set to one of: #{valid_modes.join(", ")}. Current: #{mode.inspect}")
    end
    mode
  end
end

# trigger loading of the settings
AppSettings.instance

# Validate app mode first and foremost
AppSettings.app_mode
