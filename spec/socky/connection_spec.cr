require "../spec_helper"

describe Socky::Connection do
  describe "subscription bookkeeping" do
    it "remembers and forgets subscriptions" do
      conn, _io = make_socky_connection

      conn.remember_subscription("test:one")
      conn.remember_subscription("test:two")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should contain("test:one")
      keys.should contain("test:two")

      conn.forget_subscription("test:one")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should eq(["test:two"])
    end

    it "remembers subscriptions added via Hub#subscribe" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "test:via_hub")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should eq(["test:via_hub"])
    end

    it "clears all subscriptions on Hub#disconnect" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "test:ch1")
      Socky::Hub.subscribe(conn, "test:ch2")
      Socky::Hub.disconnect(conn)

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should be_empty
    end

    it "forgets subscriptions when unsubscribed via Hub#unsubscribe" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "test:ch1")
      Socky::Hub.unsubscribe(conn, "test:ch1")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should be_empty
    end
  end
end
