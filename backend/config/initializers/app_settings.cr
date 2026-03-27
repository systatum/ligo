require "yaml"

require "./app_info"

class AppSettings
  include TypedEnvConfig

  field ligo_app_cors_whitelist : String, default: ""
  field ligo_app_cors_ok_headers : String, default: ""
  field ligo_app_salt_for_id_concealer : String, default: ""
  field ligo_app_base_url : String, default: "http://localhost:8000"
  field ligo_app_password_reset_token_expiry_minutes : Int32, default: 5

  field ligo_database_host : String, default: ""
  field ligo_database_port : Int32, default: 0
  field ligo_database_name : String, default: ""
  field ligo_database_user : String, default: ""
  field ligo_database_password : String, default: ""

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

  field ligo_sidekiq_redis_host : String, default: "127.0.0.1"
  field ligo_sidekiq_redis_port : Int32, default: 6379
  field ligo_sidekiq_redis_password : String, default: ""
  field ligo_sidekiq_redis_database_number : Int32, default: 0
  field ligo_sidekiq_dashboard_session_secret : String, default: "" # A secret key used to secure the Sidekiq dashboard session
  field ligo_sidekiq_job_status_expiry : Int32, default: 86_400     # The expiration time in seconds for the job status

  @@instance : AppSettings?

  @@app_mode : String? = nil

  def self.instance
    @@instance ||= AppSettings.load_from_yaml_file!("./app_settings.yml", Marten.env.id)
  end

  def self.app_mode : String
    return @@app_mode.not_nil! if @@app_mode
    mode = ENV["LIGO_APP_MODE"]?
    valid_modes = AppInfo.all.keys
    unless mode && valid_modes.includes?(mode)
      raise Exception.new("LIGO_APP_MODE must be set to one of: #{valid_modes.join(", ")}. Current: #{mode.inspect}")
    end
    @@app_mode = mode
    mode.not_nil!
  end

  def app_mode : String
    self.class.app_mode
  end
end

# trigger loading of the settings
AppSettings.instance

# Validate app mode first and foremost
AppSettings.app_mode
