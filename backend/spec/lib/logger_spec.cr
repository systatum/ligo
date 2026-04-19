require "./spec_helper"

describe Logger do
  describe ".instance" do
    it "creates the log directory and a log file relative to the working directory" do
      Logger.reset_instance

      Logger.instance

      Dir.exists?(File.join(Dir.current, "log")).should be_true
      Dir.glob(File.join(Dir.current, "log", "test.log")).should_not be_empty
    end
  end

  describe ".debug" do
    it "emits a debug JSON line on the ligo source" do
      backend = CapturingBackend.new
      Log.setup("ligo", Log::Severity::Trace, backend)

      Logger.debug("hello from debug")

      backend.entries.size.should eq 1
      entry = backend.entries.first
      entry.severity.should eq Log::Severity::Debug
      entry.source.should eq "ligo"

      body = JSON.parse(entry.message)
      body["severity"].as_s.should eq "DEBUG"
      body["message"].as_s.should eq "hello from debug"
      body["stacktrace"].raw.should be_nil
      body["when"].as_s.ends_with?("+07:00").should be_true
    end

    it "suppresses debug entries when the source is at Info level" do
      backend = CapturingBackend.new
      Log.setup("ligo", Log::Severity::Info, backend)

      Logger.debug("suppressed debug")

      backend.entries.should be_empty
    end
  end

  describe ".info" do
    it "emits an info JSON line on the ligo source" do
      backend = CapturingBackend.new
      Log.setup("ligo", Log::Severity::Trace, backend)

      Logger.info("hello from info")

      backend.entries.size.should eq 1
      entry = backend.entries.first
      entry.severity.should eq Log::Severity::Info
      entry.source.should eq "ligo"

      body = JSON.parse(entry.message)
      body["severity"].as_s.should eq "INFO"
      body["message"].as_s.should eq "hello from info"
      body["stacktrace"].raw.should be_nil
    end

    it "allows info entries when the source is at Info level" do
      backend = CapturingBackend.new
      Log.setup("ligo", Log::Severity::Info, backend)

      Logger.info("visible info")

      backend.entries.size.should eq 1
    end
  end

  describe ".error" do
    it "emits an error JSON line on the ligo source" do
      backend = CapturingBackend.new
      Log.setup("ligo", Log::Severity::Trace, backend)

      Logger.error("something went wrong")

      backend.entries.size.should eq 1
      entry = backend.entries.first
      entry.severity.should eq Log::Severity::Error
      entry.source.should eq "ligo"

      body = JSON.parse(entry.message)
      body["severity"].as_s.should eq "ERROR"
      body["message"].as_s.should eq "something went wrong"
    end

    it "attaches the exception when one is provided" do
      backend = CapturingBackend.new
      Log.setup("ligo", Log::Severity::Trace, backend)

      ex = begin
        raise "boom"
      rescue e
        e
      end
      Logger.error("error with exception", ex)

      entry = backend.entries.first
      entry.severity.should eq Log::Severity::Error
      entry.exception.should eq ex

      body = JSON.parse(entry.message)
      body["message"].as_s.should eq "error with exception"
      body["exception_class"].as_s.should eq "Exception"
      body["stacktrace"].as_a.should_not be_empty
    end

    it "has no exception attached when called without one" do
      backend = CapturingBackend.new
      Log.setup("ligo", Log::Severity::Trace, backend)

      Logger.error("plain error")

      backend.entries.first.exception.should be_nil
    end

    it "emits even when the source level is set to Info" do
      backend = CapturingBackend.new
      Log.setup("ligo", Log::Severity::Info, backend)

      Logger.error("always visible")

      backend.entries.size.should eq 1
    end
  end
end
