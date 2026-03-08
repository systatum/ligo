require "dotenv"

Dotenv.load if File.exists?(".env")

module S3Config
  def self.configure(config)
    config.media_files.storage = MartenS3::Store.new(
      region: ENV.fetch("LIGO_S3_REGION", AppSettings.instance.ligo_s3_region),
      bucket: ENV.fetch("LIGO_S3_BUCKET", AppSettings.instance.ligo_s3_bucket),
      access_key: ENV.fetch("LIGO_S3_ACCESS_KEY", AppSettings.instance.ligo_s3_access_key),
      secret_key: ENV.fetch("LIGO_S3_SECRET_KEY", AppSettings.instance.ligo_s3_secret_key),
      endpoint: ENV.fetch("LIGO_S3_ENDPOINT", AppSettings.instance.ligo_s3_endpoint),
      force_path_style: ENV.fetch(
        "LIGO_S3_FORCE_PATH_STYLE",
        AppSettings.instance.ligo_s3_force_path_style.to_s
      ) == "true",
    )
  end
end
