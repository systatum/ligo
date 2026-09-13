module Ligo
  class User::EmailVerificationSendJob
    include Sidekiq::Worker

    sidekiq_options do |job|
      job.queue = "mailers"
      job.retry = 5
    end

    def perform(email : String, redirection_uri : String?, expired_at_iso : String?) : EmailDeliveryResult?
      user = User.get_by_natural_key(email)
      if user.nil?
        Logger.info("EmailVerificationSendJob: user not found for email #{email}")
        return nil
      end

      if user.is_email_address_verified?
        Logger.info("EmailVerificationSendJob: email already verified for #{email}")
        return nil
      end

      expired_at = expired_at_iso.presence.try { |s| Time.parse_iso8601(s) }
      token = user.generate_email_verification_token!(expired_at)
      user.save!

      result = User::MailerService.send_verification_email(
        user: user,
        token: token,
        redirection_uri: redirection_uri,
      )

      raise result.error.try(&.message) || "Email delivery failed" if !result.success

      result
    end
  end
end
