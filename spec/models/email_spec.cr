require "../spec_helper"

describe Email do
  describe ".deliver_email_content" do
    it "renders markdown content into the branded HTML template and delivers it" do
      result = Email.deliver_email_content(
        to: [{name: "Jane Doe", email: "jane@example.com"}],
        subject: "Hello from Ligo",
        content: "**Welcome** to the platform.\n\n- item one\n- item two",
        app_name: "MyApp",
        app_description: "MyApp does things.",
        from_email: "sender@example.com",
        from_name: "Sender"
      )

      result.success.should be_true
      result.error.should be_nil

      delivered = Marten::Emailing::Backend::Development.delivered_emails.last
      delivered.subject.should eq "Hello from Ligo"
      delivered.to.map(&.to_s).should contain %("Jane Doe" <jane@example.com>)
      delivered.from.to_s.should eq %("Sender" <sender@example.com>)

      html = delivered.html_body.not_nil!
      html.should contain "<strong>Welcome</strong>"
      html.should contain "<li>item one</li>"
      html.should contain "MyApp"
      html.should contain "MyApp does things."
    end

    it "defaults branding and sender to AppSettings when not given" do
      result = Email.deliver_email_content(
        to: [{name: "Jane Doe", email: "jane@example.com"}],
        subject: "Defaults",
        content: "hi"
      )

      result.success.should be_true

      delivered = Marten::Emailing::Backend::Development.delivered_emails.last
      delivered.from.to_s.should eq %("#{AppSettings.instance.ligo_mailer_from_name}" <#{AppSettings.instance.ligo_mailer_from_email}>)
      delivered.html_body.not_nil!.should contain AppSettings.instance.ligo_mailer_app_name
    end
  end
end
