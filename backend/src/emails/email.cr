require "markd"
require "socket"

class EmailDeliveryResult
  getter email : Email
  getter success : Bool
  getter error : Exception?

  def initialize(@email : Email, @success : Bool, @error : Exception?)
  end
end

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
    company : String,
    company_address : String,
    company_image : String,
  )
    @receiver_signatures = to.map { |r| Marten::Emailing::Address.new(r[:email], r[:name]) }
    @sender_signature = Marten::Emailing::Address.new(from_email, from_name)
    @subject = subject

    context[:subject] = subject
    context[:content_html] = content_html
    context[:company] = company
    context[:companyAddress] = company_address
    context[:companyImage] = company_image
  end

  def self.build_email_from_content(
    to : Array(NamedTuple(name: String, email: String)),
    subject : String,
    content : String,
    from_email : String = default_sender_email,
    from_name : String = default_sender_name,
  ) : Email
    html = Markd.to_html(content)

    app = AppSettings.instance
    company = app.ligo_mailer_company_name
    company_address = app.ligo_mailer_company_address
    company_image = app.ligo_mailer_company_image

    self.new(
      to: to,
      subject: subject,
      content_html: html,
      from_email: from_email,
      from_name: from_name,
      company: company,
      company_address: company_address,
      company_image: company_image,
    )
  end

  def self.deliver_email_content(
    to : Array(NamedTuple(name: String, email: String)),
    subject : String,
    content : String,
    from_email : String = default_sender_email,
    from_name : String = default_sender_name,
  ) : EmailDeliveryResult
    validate_smtp_configuration!
    email = build_email_from_content(to, subject, content, from_email, from_name)
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
    if host.nil? || host.empty? || port == 0
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
end
