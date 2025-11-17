require "../spec_helper"
require "../../config/settings/concerns/smtp_config"

describe Email do
  before_each do
    Marten.configure do |config|
      SMTPConfig.configure(config)
    end
  end

  after_each do
    Marten.configure :test do |config|
      config.emailing.backend = Marten::Emailing::Backend::Development.new(collect_emails: true, print_emails: false)
    end
  end

  it "builds an email from markdown and recipients" do
    to = [{name: "Alice", email: "alice@example.com"}] of NamedTuple(name: String, email: String)
    subject = "Test Subject"
    content = "# Hello\n\nThis is a test."

    email = Email.build_email_from_content(to, subject, content)

    email.should be_a(Email)
    email.from.address.should eq "noreply@workaty.com"
    email.to.first.address.should eq "alice@example.com"
    email.subject.should eq "Test Subject"
    email.context[:content_html].raw.as(String).should contain("<h1>Hello</h1>")
  end

  it "returns a delivery result with success boolean" do
    to = [{name: "Alice", email: "alice@example.com"}] of NamedTuple(name: String, email: String)
    result = Email.deliver_email_content(to, "Subject", "Body")
    result.should be_a(EmailDeliveryResult)
    result.email.should be_a(Email)
    result.success.should eq true
  end

  it "builds with multiple recipients" do
    to = [
      {name: "Alice", email: "alice@example.com"},
      {name: "Bob", email: "bob@example.com"},
    ] of NamedTuple(name: String, email: String)
    email = Email.build_email_from_content(to, "Hello", "Body")
    email.should be_a(Email)
  end

  it "sets custom from_email and from_name" do
    to = [{name: "Customer", email: "customer@example.com"}] of NamedTuple(name: String, email: String)
    result = Email.deliver_email_content(
      to,
      "Custom Sender",
      "Hello",
      from_email: "support@custom.com",
      from_name: "Custom Support"
    )

    result.email.from.address.should eq "support@custom.com"
    result.email.from.name.should eq "Custom Support"
  end

  it "renders markdown content including headings, paragraphs, buttons, and links" do
    to = [{name: "Alice", email: "alice@example.com"}] of NamedTuple(name: String, email: String)
    subject = "Please confirm your email"
    content = <<-MD
    Yes, we know

    An email to confirm an email.

    Please validate your email address in order to get started using Workaty

    <a href="https://workaty.com/confirm" style="display:inline-block;background:#569aec;color:white;font-family:Ubuntu, Helvetica, Arial, sans-serif;font-size:14px;font-weight:500;line-height:120%;margin:0;text-decoration:none;text-transform:none;padding:10px 25px;border-radius:2px;">Confirm Your Email</a>

    Or verify using this link:

    <a font-size="14px" href="https://workaty.com" style="color: #408ee8">
        https://workaty.com
    </a>

    ## Need Help?

    Please send and feedback or bug info

    to <a font-size="14px" href="https://workaty.com" style="color: #408ee8">
        https://workaty.com
    </a>

    MD

    result = Email.deliver_email_content(to, subject, content)
    result.success.should be_true
  end

  it "renders complex markdown with lists, code blocks, and tables" do
    to = [{name: "Developer", email: "dev@example.com"}] of NamedTuple(name: String, email: String)
    content = <<-MD
    # Release Notes

    ## New Features

    - Feature A: Enhanced performance
    - Feature B: New dashboard
    - Feature C: API improvements

    ## Code Example

    ```crystal
    def hello
      puts "Hello, World!"
    end
    ```

    ## Breaking Changes

    <table cellpadding="12" cellspacing="0" border="0" style="border-collapse:collapse;font-family:Arial,sans-serif;font-size:14px">
        <thead>
            <tr style="background:#f5f5f5">
                <th align="left" style="padding:12px;font-weight:600;color:#666">API Endpoint</th>
                <th align="left" style="padding:12px;font-weight:600;color:#666">Old Version</th>
                <th align="left" style="padding:12px;font-weight:600;color:#666">New Version</th>
            </tr>
        </thead>
        <tbody>
            <tr style="border-top:1px solid #ddd">
                <td style="padding:12px;font-family:monospace">/users</td>
                <td style="padding:12px;color:#999">v1</td>
                <td style="padding:12px;color:#0066cc">v2</td>
            </tr>
            <tr style="border-top:1px solid #ddd">
                <td style="padding:12px;font-family:monospace">/posts</td>
                <td style="padding:12px;color:#999">v1</td>
                <td style="padding:12px;color:#0066cc">v2</td>
            </tr>
        </tbody>
    </table>

    **Important:** Please update your integrations.
    MD

    result = Email.deliver_email_content(to, "Release v2.0", content)
    html = result.email.context[:content_html].raw.as(String)

    html.should contain("<h1>Release Notes</h1>")
    html.should contain("<h2>New Features</h2>")
    html.should contain("<li>Feature A: Enhanced performance</li>")
    html.should contain("<code")
    html.should contain("<table")
    html.should contain("<strong>Important:</strong>")
  end

  it "handles mixed content with blockquotes and emphasis" do
    to = [
      {name: "Alice", email: "alice@example.com"},
      {name: "Bob", email: "bob@example.com"},
    ] of NamedTuple(name: String, email: String)

    content = <<-MD
    # Welcome to the Team!

    We're *excited* to have you **onboard**.

    > "The best way to predict the future is to invent it." - Alan Kay

    Here's what you need to do:

    1. Set up your account
    2. Complete your profile
    3. Join the team chat

    ---

    Questions? Reply to this email or visit our [Help Center](https://help.workaty.com).
    MD

    result = Email.deliver_email_content(to, "Welcome!", content)
    html = result.email.context[:content_html].raw.as(String)

    html.should contain("<em>excited</em>")
    html.should contain("<strong>onboard</strong>")
    html.should contain("<blockquote>")
    html.should contain("<ol>")
    html.should contain("<hr")
    html.should contain("href=\"https://help.workaty.com\"")
  end

  it "preserves inline HTML styles in markdown" do
    to = [{name: "User", email: "user@example.com"}] of NamedTuple(name: String, email: String)
    content = <<-MD
    # Styled Content

    <div style="background-color: #f0f0f0; padding: 20px; border-radius: 5px;">
      This is a styled box with custom CSS.
    </div>

    <p style="color: red; font-weight: bold;">Important notice!</p>
    MD

    result = Email.deliver_email_content(to, "Styled Email", content)
    html = result.email.context[:content_html].raw.as(String)

    html.should contain("background-color: #f0f0f0")
    html.should contain("padding: 20px")
    html.should contain("color: red")
  end
end
