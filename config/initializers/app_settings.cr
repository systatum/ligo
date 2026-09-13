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

  field ligo_sidekiq_redis_host : String, default: "127.0.0.1"
  field ligo_sidekiq_redis_port : Int32, default: 6379
  field ligo_sidekiq_redis_password : String, default: ""
  field ligo_sidekiq_redis_database_number : Int32, default: 0
  field ligo_sidekiq_dashboard_session_secret : String, default: "" # secures the Sidekiq dashboard session
  field ligo_sidekiq_job_status_expiry : Int32, default: 86_400     # expiration in seconds for job status

  field ligo_mailer_smtp_host : String, default: ""
  field ligo_mailer_smtp_port : Int32, default: 0
  field ligo_mailer_smtp_domain : String, default: ""
  field ligo_mailer_smtp_username : String, default: ""
  field ligo_mailer_smtp_password : String, default: ""
  field ligo_mailer_smtp_use_auth : Bool, default: false
  field ligo_mailer_smtp_use_starttls : Bool, default: false

  field ligo_mailer_from_email : String, default: "noreply@example.com"
  field ligo_mailer_from_name : String, default: "Ligo"
  field ligo_mailer_app_name : String, default: "Ligo"
  field ligo_mailer_app_description : String, default: ""

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
