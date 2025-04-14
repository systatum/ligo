class Workaty::GenericEmail < Marten::Email
  from @sender_signature
  to @receiver_signature
  subject @subject
  template_name "emails/generic_email.txt", content_type: :text

  def initialize(
    receiver_email : String,
    receiver_name : String,
    sender_email : String,
    sender_name : String,
    subject : String,
    content : String
  )
    @receiver_signature = Marten::Emailing::Address.new(receiver_email, receiver_name)
    @sender_signature = Marten::Emailing::Address.new(sender_email, sender_name)
    @subject = subject

    # give out the context
    context[:receiver_name] = receiver_name
    context[:content] = content
  end
end
