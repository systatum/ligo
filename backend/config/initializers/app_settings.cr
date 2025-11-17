require "yaml"

class AppSettings
  include TypedEnvConfig

  field ligo_app_cors_whitelist : String, default: ""
  field ligo_app_cors_ok_headers : String, default: ""
  field ligo_app_salt_for_id_concealer : String, default: ""

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

  @@instance : AppSettings?

  def self.instance
    @@instance ||= AppSettings.load_from_yaml_file!("./app_settings.yml", Marten.env.id)
  end
end

# trigger loading of the settings
AppSettings.instance
