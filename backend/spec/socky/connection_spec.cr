require "./spec_helper"

describe Socky::Connection do
  describe "subscription bookkeeping" do
    it "remembers and forgets subscriptions" do
      conn, _io = make_socky_connection

      conn.remember_subscription("antrikan:test1")
      conn.remember_subscription("antrikan:test2")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should contain("antrikan:test1")
      keys.should contain("antrikan:test2")

      conn.forget_subscription("antrikan:test1")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should eq(["antrikan:test2"])
    end

    it "remembers subscriptions added via Hub#subscribe" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "antrikan:via_hub")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should eq(["antrikan:via_hub"])
    end

    it "clears all subscriptions on Hub#disconnect" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "antrikan:ch1")
      Socky::Hub.subscribe(conn, "antrikan:ch2")
      Socky::Hub.disconnect(conn)

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should be_empty
    end

    it "forgets subscriptions when unsubscribed via Hub#unsubscribe" do
      conn, _io = make_socky_connection

      Socky::Hub.subscribe(conn, "antrikan:ch1")
      Socky::Hub.unsubscribe(conn, "antrikan:ch1")

      keys = [] of String
      conn.each_subscribed_channel_key { |k| keys << k }
      keys.should be_empty
    end
  end
end
