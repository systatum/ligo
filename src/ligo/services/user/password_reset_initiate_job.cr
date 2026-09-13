module Ligo
  # This job initiates a password reset flow and sends an email to the associated user.
  class User::PasswordResetInitiateJob
    include Sidekiq::Worker

    sidekiq_options do |job|
      job.queue = "mailers"
      job.retry = 5
    end

    def perform(email : String) : EmailDeliveryResult?
      user = User.get_by_natural_key(email)
      if user.nil?
        Log.info { "PasswordResetInitiateJob: user not found for email #{email}" }
        return nil
      end

      token = user.generate_password_reset_token
      user.save!

      result = User::MailerService.send_password_reset_email(user)

      raise result.error.try(&.message) || "Email delivery failed" if !result.success

      result
    end
  end
end
