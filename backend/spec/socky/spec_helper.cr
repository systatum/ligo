require "../spec_helper"

# A minimal IO that captures writes, for verifying WebSocket sends
# without needing a real TCP socket.
class TestIO < IO
  getter buffer : IO::Memory = IO::Memory.new

  def read(slice : Bytes) : Int32
    0
  end

  def write(slice : Bytes) : Nil
    buffer.write(slice)
  end

  def closed? : Bool
    false
  end

  def includes?(str : String) : Bool
    buffer.to_s.includes?(str)
  end
end

def make_socky_connection(user : Auth::User? = nil) : {Socky::Connection, TestIO}
  user ||= create_user
  io = TestIO.new
  ws = ::HTTP::WebSocket.new(io)
  {Socky::Connection.new(user, ws), io}
end
