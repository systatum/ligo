require "awscr-s3"

# Thin wrapper over the S3-compatible client/presigner; the bucket is always supplied by the
# caller, this module owns no bucket-specific configuration of its own.
module S3PresignerService
  PRESIGNED_PUT_EXPIRES_SECONDS = 300
  PRESIGNED_GET_EXPIRES_SECONDS = 300

  def self.presigned_put_url(bucket : String, key : String) : String
    presign(bucket, key, PRESIGNED_PUT_EXPIRES_SECONDS).for(:put)
  end

  def self.presigned_get_url(bucket : String, key : String) : String
    presign(bucket, key, PRESIGNED_GET_EXPIRES_SECONDS).for(:get)
  end

  def self.delete_object(bucket : String, key : String) : Nil
    client.delete_object(bucket, key)
  end

  private def self.presign(bucket : String, key : String, expires : Int32) : Awscr::S3::Presigned::Url
    settings = AppSettings.instance
    options = Awscr::S3::Presigned::Url::Options.new(
      aws_access_key: settings.ligo_s3_access_key,
      aws_secret_key: settings.ligo_s3_secret_key,
      region: settings.ligo_s3_region,
      object: key,
      bucket: bucket,
      endpoint: endpoint,
      expires: expires,
      force_path_style: true,
    )
    Awscr::S3::Presigned::Url.new(options)
  end

  private def self.client : Awscr::S3::Client
    settings = AppSettings.instance
    Awscr::S3::Client.new(
      settings.ligo_s3_region,
      settings.ligo_s3_access_key,
      settings.ligo_s3_secret_key,
      endpoint: endpoint,
    )
  end

  private def self.endpoint : String?
    value = AppSettings.instance.ligo_s3_endpoint
    value.empty? ? nil : value
  end
end
