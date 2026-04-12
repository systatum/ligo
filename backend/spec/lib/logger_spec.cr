require "./spec_helper"

describe Logger do
  describe ".setup" do
    it "creates the log directory and a log file relative to the working directory" do
      tmpdir = File.join(Dir.tempdir, "logger_spec_#{Random::Secure.hex(6)}")
      Dir.mkdir_p(tmpdir)
      original_dir = Dir.current
      Dir.cd(tmpdir)

      begin
        Logger.setup

        Dir.exists?(File.join(tmpdir, "log")).should be_true
        Dir.glob(File.join(tmpdir, "log", "*.log")).should_not be_empty
      ensure
        Dir.cd(original_dir)
        FileUtils.rm_rf(tmpdir)
      end
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
      body["severity"].as_s.should eq "debug"
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
      body["severity"].as_s.should eq "info"
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
      body["severity"].as_s.should eq "error"
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
