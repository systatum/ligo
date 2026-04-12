module S3Config
  def self.configure(config)
    settings = AppSettings.instance
    config.media_files.storage = MartenS3::Store.new(
      region: settings.ligo_s3_region,
      bucket: settings.ligo_s3_bucket,
      access_key: settings.ligo_s3_access_key,
      secret_key: settings.ligo_s3_secret_key,
      endpoint: settings.ligo_s3_endpoint,
      force_path_style: settings.ligo_s3_force_path_style,
    )
  end
end
