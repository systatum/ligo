class Socky::Hub
  @@mutex = Mutex.new
  @@rooms = Hash(String, Room).new

  def self.subscribe(connection : Socky::Connection, channel_key : String) : Nil
    @@mutex.synchronize do
      room = @@rooms[channel_key] ||= Room.new
      room.add(connection)
      connection.remember_subscription(channel_key)
    end
  end

  def self.unsubscribe(connection : Socky::Connection, channel_key : String) : Nil
    @@mutex.synchronize do
      leave_room(connection, channel_key)
      connection.forget_subscription(channel_key)
    end
  end

  def self.disconnect(connection : Socky::Connection) : Nil
    @@mutex.synchronize do
      keys = [] of String
      connection.each_subscribed_channel_key { |k| keys << k }
      keys.each do |channel_key|
        leave_room(connection, channel_key)
        connection.forget_subscription(channel_key)
      end
    end
  end

  # Test-only: clears all rooms. Used by specs for isolation.
  def self.clear! : Nil
    @@mutex.synchronize { @@rooms.clear }
  end

  # Local delivery only. Reaching connections on other processes is
  # Socky::Broadcaster's job, not this class's.
  def self.deliver_locally(channel_key : String, payload_json : String) : Nil
    connections = @@mutex.synchronize do
      room = @@rooms[channel_key]?
      room ? room.connections : nil
    end
    return unless connections

    connections.each do |connection|
      connection.socket.send(payload_json)
    rescue IO::Error
      disconnect(connection)
    end
  end

  # Must be called with @@mutex already held. Removes a connection from
  # a room, deleting the room entirely once nobody's left in it.
  private def self.leave_room(connection : Socky::Connection, channel_key : String) : Nil
    room = @@rooms[channel_key]?
    return unless room

    room.remove(connection)
    @@rooms.delete(channel_key) if room.empty?
  end
end

# Every connection currently subscribed to one channel.
class Socky::Hub::Room
  def initialize
    @connections = Set(Socky::Connection).new
  end

  def add(connection : Socky::Connection) : Nil
    @connections << connection
  end

  def remove(connection : Socky::Connection) : Nil
    @connections.delete(connection)
  end

  def empty? : Bool
    @connections.empty?
  end

  # A snapshot copy, not the live Set. Callers broadcast over this
  # outside the Hub's mutex, so it must not alias mutable state.
  def connections : Array(Socky::Connection)
    @connections.to_a
  end
end
