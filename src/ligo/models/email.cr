require "markd"
require "socket"

class EmailDeliveryResult
  getter email : Email
  getter success : Bool
  getter error : Exception?

  def initialize(@email : Email, @success : Bool, @error : Exception?)
  end
end

# Renders markdown content into a branded HTML email and delivers it over
# SMTP. Branding (app_name/app_description) defaults to whatever this
# deployment configured in AppSettings, but any caller can override it
# directly - there's no app mode/registry indirection here, that was a
# concept specific to the old monorepo's multiple products sharing one
# codebase, not something Ligo itself needs to know about.
class Email < Marten::Email
  from @sender_signature
  to @receiver_signatures
  subject @subject
  template_name "emails/email.html", content_type: :html

  @receiver_signatures : Array(Marten::Emailing::Address)

  def initialize(
    to : Array(NamedTuple(name: String, email: String)),
    subject : String,
    content_html : String,
    from_email : String,
    from_name : String,
    app_name : String,
    app_description : String,
    current_year : String,
  )
    @receiver_signatures = to.map { |r| Marten::Emailing::Address.new(r[:email], r[:name]) }
    @sender_signature = Marten::Emailing::Address.new(from_email, from_name)
    @subject = subject

    context[:subject] = subject
    context[:content_html] = content_html
    context[:app_name] = app_name
    context[:app_description] = app_description
    context[:current_year] = current_year
  end

  def self.build_email_from_content(
    to : Array(NamedTuple(name: String, email: String)),
    subject : String,
    content : String,
    app_name : String = default_app_name,
    app_description : String = default_app_description,
    from_email : String = default_sender_email,
    from_name : String = default_sender_name,
  ) : Email
    html = Markd.to_html(content)

    self.new(
      to: to,
      subject: subject,
      content_html: html,
      from_email: from_email,
      from_name: from_name,
      app_name: app_name,
      app_description: app_description,
      current_year: Time.local.year.to_s,
    )
  end

  def self.deliver_email_content(
    to : Array(NamedTuple(name: String, email: String)),
    subject : String,
    content : String,
    app_name : String = default_app_name,
    app_description : String = default_app_description,
    from_email : String = default_sender_email,
    from_name : String = default_sender_name,
  ) : EmailDeliveryResult
    validate_smtp_configuration!
    email = build_email_from_content(to, subject, content, app_name, app_description, from_email, from_name)
    begin
      email.deliver
      EmailDeliveryResult.new(email, true, nil)
    rescue ex
      EmailDeliveryResult.new(email, false, ex)
    end
  end

  private def self.validate_smtp_configuration!
    app = AppSettings.instance
    host = app.ligo_mailer_smtp_host
    port = app.ligo_mailer_smtp_port
    if host.empty? || port == 0
      raise "SMTP configuration invalid: host='#{host}' port='#{port}'"
    end
    begin
      socket = TCPSocket.new(host, port, connect_timeout: 2.seconds)
      socket.close
    rescue ex
      raise "SMTP connectivity check failed for #{host}:#{port} (#{ex.class}: #{ex.message})"
    end
  end

  private def self.default_sender_email : String
    AppSettings.instance.ligo_mailer_from_email
  end

  private def self.default_sender_name : String
    AppSettings.instance.ligo_mailer_from_name
  end

  private def self.default_app_name : String
    AppSettings.instance.ligo_mailer_app_name
  end

  private def self.default_app_description : String
    AppSettings.instance.ligo_mailer_app_description
  end
end
