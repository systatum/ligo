require "yaml"

class AppSettings
  include TypedEnvConfig

  field ligo_app_cors_whitelist : String, default: ""
  field ligo_app_cors_ok_headers : String, default: ""
  field ligo_app_salt_for_id_concealer : String, default: ""

  field ligo_mailer_smtp_host : String, default: ""
  field ligo_mailer_smtp_port : Int32, default: 0
  field ligo_mailer_smtp_domain : String, default: ""
  field ligo_mailer_smtp_username : String, default: ""
  field ligo_mailer_smtp_password : String, default: ""
  field ligo_mailer_smtp_use_auth : Bool, default: false
  field ligo_mailer_smtp_use_smtps : Bool, default: false
  field ligo_mailer_smtp_use_starttls : Bool, default: false

  @@instance : AppSettings?

  def self.instance
    @@instance ||= AppSettings.load_from_yaml_file!("./app_settings.yml", Marten.env.id)
  end
end

# trigger loading of the settings
AppSettings.instance
