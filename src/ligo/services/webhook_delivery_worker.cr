require "openssl/hmac"

# A signed webhook delivery job.
class WebhookDeliveryWorker
  include Sidekiq::Worker

  sidekiq_options do |job|
    job.queue = "webhook"
    job.retry = false
  end

  def perform(content_id : String, uri : String, webhook_secret : String, body : String, ack_semantic : AcknowledgeSemantic? = nil)
    return if ack_semantic == AcknowledgeSemantic::NONE

    timestamp = Time.utc.to_unix.to_s
    signature = OpenSSL::HMAC.hexdigest(:sha256, webhook_secret, "#{body}#{timestamp}")

    response = Halite
      .timeout(connect: 5.0, read: 10.0)
      .post(
        uri,
        headers: {
          "Content-Type"         => "application/json",
          "X-Systatum-Timestamp" => timestamp,
          "X-Systatum-Signature" => signature,
        },
        raw: body,
      )

    if response.status_code == 200 || response.status_code == 204
      Ligo::WebhookDelivery.create!(content_id: content_id, succeeded: true)

      if ack_semantic == AcknowledgeSemantic::MUTUAL
        if realm_user = Ligo::RealmUser.filter(registration_webhook_content_id: content_id).first?
          realm_user.update!(acked_at: Time.utc)
        end
      end
    else
      Ligo::WebhookDelivery.create!(content_id: content_id, succeeded: false)
      raise "Webhook delivery failed: HTTP #{response.status_code}" if ack_semantic == AcknowledgeSemantic::MUTUAL
    end
  rescue e : Halite::Error
    Ligo::WebhookDelivery.create!(content_id: content_id, succeeded: false)
    raise e if ack_semantic == AcknowledgeSemantic::MUTUAL
  end
end
