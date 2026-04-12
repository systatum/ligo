require "../spec_helper"

# Captures Log::Entry values emitted through a given log source.
class CapturingBackend < Log::Backend
  getter entries : Array(Log::Entry) = [] of Log::Entry

  def initialize
    # Uses :sync DispatchMode so entries are written immediately.
    super(:sync)
  end

  def write(entry : Log::Entry) : Nil
    @entries << entry
  end
end
