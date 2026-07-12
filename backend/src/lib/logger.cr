Log.define_formatter LoggerMessageOnlyFormatter, "#{message}"

# This class is to provide centralized logging service for Ligo, which
# currently, is tightly coupled with Crystal's standard Log implementation.
# We broadcast logs to three separate outputs: stdout, stderr, and a file.
class Logger
  LOG_FILE_DIR = Path["log"]

  NOISE_STACKTRACE_LINES = [
    "lib/marten",
    "marten/src/",
    "crystal/src",
    "crystal/core/",
    "??",
  ]

  private def initialize
    @log = Log.for("ligo")
    setup
  end

  private def setup
    file = open_log_file

    broadcast = Log::BroadcastBackend.new

    unless Marten.env.test?
      broadcast.append(Log::IOBackend.new(file, formatter: LoggerMessageOnlyFormatter), Log::Severity::Trace)
      broadcast.append(Log::IOBackend.new(STDERR, formatter: LoggerMessageOnlyFormatter), Log::Severity::Error)
    end

    # always write to the file (helpful for debugging test failures later)
    broadcast.append(Log::IOBackend.new(formatter: LoggerMessageOnlyFormatter), Log::Severity::Trace)

    Log.setup_from_env(backend: broadcast)
  end

  def self.instance
    @@instance ||= new
  end

  def self.debug(message : String)
    instance.debug(message)
  end

  def self.info(message : String)
    instance.info(message)
  end

  def self.error(message : String, *, err : Exception? = nil, notify : Bool = false)
    instance.error(message, err: err, notify: notify)
  end

  def self.warn(message : String, e : Exception? = nil)
    instance.warn(message, e)
  end

  def debug(message : String)
    @log.debug { payload("debug", message) }
  end

  def info(message : String)
    @log.info { payload("info", message) }
  end

  def error(message : String, *, err : Exception? = nil, notify : Bool = false)
    if err
      @log.error(exception: err) { payload("error", message, err) }
    else
      @log.error { payload("error", message) }
    end

    notify_sentry(message, err) if notify
  end

  def warn(message : String, e : Exception? = nil)
    if e
      @log.warn(exception: e) { payload("warn", message, e) }
    else
      @log.warn { payload("warn", message) }
    end
  end

  # TODO: send to Sentry
  private def notify_sentry(message : String, err : Exception?) : Nil
  end

  private def payload(severity : String, message : String, e : Exception? = nil) : String
    JSON.build do |json|
      json.object do
        json.field "when", current_time_wib
        json.field "ip", Current.ip
        json.field "user_id", Current.performer_id
        json.field "path", Current.path
        json.field "severity", severity.upcase
        json.field "message", message
        json.field "exception_class", e.try(&.class.to_s)

        stacktrace = stacktrace(e)
        if stacktrace
          json.field "stacktrace" do
            json.array do
              stacktrace.each do |line|
                json.string line
              end
            end
          end
        else
          json.field "stacktrace", nil
        end
      end
    end
  end

  private def current_time_wib : String
    time = Time.local Time::Location.load("Asia/Jakarta")
    Time::Format::ISO_8601_DATE_TIME.format(time)
  end

  private def stacktrace(e : Exception?) : Array(String)?
    return nil unless e

    lines = e.backtrace? || [] of String
    return lines unless ENV["MARTEN_ENV"]? == "test"

    lines.reject do |line|
      NOISE_STACKTRACE_LINES.any? { |noise| line.includes?(noise) }
    end
  end

  private def open_log_file : IO
    Dir.mkdir_p(LOG_FILE_DIR)

    if Marten.env.development? || Marten.env.test?
      # just use a single file
      filename = "#{Marten.env.id}.log"
    else
      timestamp = Time.utc.to_s("%Y%m%d_%H%M%S")
      filename = "#{Marten.env.id}_#{timestamp}.log"
    end

    path = LOG_FILE_DIR / Path.new(filename)
    file = File.open(path, "w")

    puts "Log file: #{path.expand}"
    file
  end
end
