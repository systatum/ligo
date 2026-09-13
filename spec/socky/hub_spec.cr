require "../spec_helper"

describe Socky::Hub do
  before_each do
    Socky::Hub.clear!
  end

  describe "#subscribe" do
    it "adds connection to room and remembers subscription" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "test:foo")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should eq(["test:foo"])
    end

    it "supports multiple connections in same room" do
      conn_a, _io_a = make_socky_connection
      conn_b, _io_b = make_socky_connection

      Socky::Hub.subscribe(conn_a, "test:foo")
      Socky::Hub.subscribe(conn_b, "test:foo")

      Socky::Hub.deliver_locally("test:foo", "hello")
    end
  end

  describe "#unsubscribe" do
    it "removes connection from room and forgets subscription" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "test:foo")
      Socky::Hub.unsubscribe(conn, "test:foo")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should be_empty
    end
  end

  describe "#disconnect" do
    it "removes connection from all subscribed rooms" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "test:foo")
      Socky::Hub.subscribe(conn, "test:bar")
      Socky::Hub.disconnect(conn)

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should be_empty
    end

    it "no-ops for a connection with no subscriptions" do
      conn, _io = make_socky_connection

      Socky::Hub.disconnect(conn)

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should be_empty
    end
  end

  describe "#deliver_locally" do
    it "sends payload to all connections in the room" do
      conn_a, io_a = make_socky_connection
      conn_b, io_b = make_socky_connection

      Socky::Hub.subscribe(conn_a, "test:foo")
      Socky::Hub.subscribe(conn_b, "test:foo")

      Socky::Hub.deliver_locally("test:foo", "hello world")

      io_a.includes?("hello world").should be_true
      io_b.includes?("hello world").should be_true
    end

    it "only sends to connections in the specified room" do
      conn_a, io_a = make_socky_connection
      conn_b, io_b = make_socky_connection

      Socky::Hub.subscribe(conn_a, "test:foo")
      Socky::Hub.subscribe(conn_b, "test:bar")

      Socky::Hub.deliver_locally("test:foo", "only for foo")

      io_a.includes?("only for foo").should be_true
      io_b.includes?("only for foo").should be_false
    end

    it "no-ops for non-existent room" do
      Socky::Hub.deliver_locally("test:nobody", "ghost message")
    end

    it "does not deliver to unsubscribed connections" do
      conn, io = make_socky_connection

      Socky::Hub.subscribe(conn, "test:foo")
      Socky::Hub.unsubscribe(conn, "test:foo")

      Socky::Hub.deliver_locally("test:foo", "after unsubscribe")

      io.includes?("after unsubscribe").should be_false
    end
  end
end
