require "../spec_helper"

class TestableUserDetector < UserDetector
  def test_detect_user(request)
    detect_user(request)
  end
end

describe UserDetector do
  describe "#call" do
    it "associates current_user from Authorization header to the request" do
      user = create_user
      token = user.jwt_token

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1", "Authorization" => "Bearer #{token}"},
      )

      middleware = UserDetector.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("OK", content_type: "text/plain", status: 200) }
      )

      request.current_user.should eq user
    end

    it "does nothing when Authorization header is missing" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )

      middleware = UserDetector.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("OK", content_type: "text/plain", status: 200) }
      )

      request.current_user.should be_nil
    end
  end

  describe "#detect_user" do
    it "returns nil when Authorization header is missing" do
      middleware = TestableUserDetector.new
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )

      middleware.test_detect_user(request).should be_nil
      request.current_user.should be_nil
    end

    it "returns nil when JWT token is empty" do
      middleware = TestableUserDetector.new
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"            => "127.0.0.1",
          "Authorization"   => "Bearer ",
          "X-Forwarded-For" => "10.0.0.1",
        },
      )

      middleware.test_detect_user(request).should be_nil
      request.current_user.should be_nil
    end

    it "returns nil when JWT token is invalid" do
      middleware = TestableUserDetector.new
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{
          "Host"            => "127.0.0.1",
          "Authorization"   => "Bearer invalid_token",
          "X-Forwarded-For" => "10.0.0.2",
        },
      )

      middleware.test_detect_user(request).should be_nil
      request.current_user.should be_nil
    end

    it "returns the user when JWT token is valid" do
      user = create_user
      middleware = TestableUserDetector.new
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1", "Authorization" => "Bearer #{user.jwt_token}"},
      )

      result = middleware.test_detect_user(request)
      result.should eq user
    end
  end
end
