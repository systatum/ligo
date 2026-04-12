require "./spec_helper"

describe IPDetector do
  describe "#client_ip" do
    it "returns the IP from X-Forwarded-For header" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/",
        headers: HTTP::Headers{"X-Forwarded-For" => "10.0.0.1"}
      )
      IPDetector.client_ip(request).should eq "10.0.0.1"
    end

    it "returns the first IP from x-forwarded-for header" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/",
        headers: HTTP::Headers{"x-forwarded-for" => "10.0.0.1, 10.0.0.2"}
      )
      IPDetector.client_ip(request).should eq "10.0.0.1"
    end

    it "returns the IP from HTTP_X_FORWARDED_FOR header" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/",
        headers: HTTP::Headers{"HTTP_X_FORWARDED_FOR" => "10.0.0.3"}
      )
      IPDetector.client_ip(request).should eq "10.0.0.3"
    end

    it "returns the IP from REMOTE_ADDR header" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/",
        headers: HTTP::Headers{"REMOTE_ADDR" => "10.0.0.4"}
      )
      IPDetector.client_ip(request).should eq "10.0.0.4"
    end

    it "prioritizes X-Forwarded-For over others" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/",
        headers: HTTP::Headers{
          "X-Forwarded-For" => "10.0.0.1",
          "REMOTE_ADDR"     => "10.0.0.4",
        }
      )
      IPDetector.client_ip(request).should eq "10.0.0.1"
    end

    it "returns 'unknown' when no headers are present" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/",
        headers: HTTP::Headers.new
      )
      IPDetector.client_ip(request).should eq "unknown"
    end

    it "returns 'unknown' when headers are empty" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/",
        headers: HTTP::Headers{"X-Forwarded-For" => ""}
      )
      IPDetector.client_ip(request).should eq "unknown"
    end
  end
end
