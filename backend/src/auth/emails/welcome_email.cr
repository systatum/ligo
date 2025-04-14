class Auth::WelcomeEmail < Marten::Email
  from @sender_address
  to @receiver.email!
  subject "Welcome to #{@app_name}"
  template_name "auth/emails/welcome_email.txt", content_type: :text

  def initialize(to : Auth::User, from : String, app_name : String)
    @receiver = to
    @sender_address = from
    @app_name = app_name

    prepare_context
  end

  private def prepare_context
    context[:receiver] = @receiver
  end
end
