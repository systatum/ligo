require "../spec_helper"

describe Marten::HTTP::Request do
  describe "#current_user" do
    it "returns nil when no user is set" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )

      request.current_user.should be_nil
    end
  end

  describe "#current_user!" do
    it "returns the user when one is set" do
      user = create_user

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )
      request.current_user = user

      request.current_user!.should eq user
    end

    it "raises when no user is set" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )

      expect_raises(NilAssertionError) do
        request.current_user!
      end
    end
  end

  describe "#current_user=" do
    it "allows setting a user" do
      user = create_user

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )
      request.current_user = user

      request.current_user.should eq user
    end

    it "allows setting to nil" do
      user = create_user

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )

      request.current_user = nil
      request.current_user.should be_nil
    end

    it "allows replacing the user" do
      user1 = create_user(email: "user1@example.com")
      user2 = create_user(email: "user2@example.com")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "127.0.0.1"},
      )
      request.current_user = user1
      request.current_user.should eq user1

      request.current_user = user2
      request.current_user.should eq user2
    end
  end
end
