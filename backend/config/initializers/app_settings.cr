require "yaml"

class AppSettings
  include TypedEnvConfig

  field ligo_app_cors_whitelist : String, default: ""
  field ligo_app_cors_ok_headers : String, default: ""

  @@instance : AppSettings?

  def self.instance
    @@instance ||= AppSettings.load_from_yaml_file!("./app_settings.yml", Marten.env.id)
  end
end

# trigger loading of the settings
AppSettings.instance
