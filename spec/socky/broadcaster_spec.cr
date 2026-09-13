require "../spec_helper"

describe Socky::Broadcaster do
  it ".publish sends payload to the correct Redis channel" do
    msg = capture_redis_message("socky:channel:test:foo") do
      Socky::Broadcaster.publish("test:foo", %({"hello":"broadcaster"}))
    end

    msg.should_not be_nil
    msg.not_nil!.should eq(%({"hello":"broadcaster"}))
  end

  it ".publish with namespaced channel key maps to correct Redis channel" do
    msg = capture_redis_message("socky:channel:antrikan:abc123") do
      Socky::Broadcaster.publish("antrikan:abc123", "namespaced payload")
    end

    msg.should_not be_nil
    msg.not_nil!.should eq("namespaced payload")
  end
end
