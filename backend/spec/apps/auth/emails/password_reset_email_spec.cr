require "./spec_helper"

describe Auth::PasswordResetEmail do
  describe "#html_body" do
    it "can be rendered" do
      # first: setup
      user = create_user(email: "test@example.com", password: "insecure")

      # second: do some action
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )

      # third: retrieve things you want to check
      email = Auth::PasswordResetEmail.new(user, request)

      # fourth: do the assertions
      email.html_body.should_not be_nil
    end
  end

  describe "#subject" do
    it "returns the expected subject" do
      user = create_user(email: "test@example.com", password: "insecure")
      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      email = Auth::PasswordResetEmail.new(user, request)

      email.subject.should eq "Reset your password"
    end
  end

  describe "#to" do
    it "returns the user email address" do
      user = create_user(email: "test@example.com", password: "insecure")
      request = Marten::HTTP::Request.new(method: "GET", resource: "/test/xyz")

      email = Auth::PasswordResetEmail.new(user, request)

      email.to.size.should eq 1
      email.to.first.address.should eq user.email
    end
  end
end
