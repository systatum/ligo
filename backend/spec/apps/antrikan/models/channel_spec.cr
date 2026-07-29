require "../spec_helper"

describe Antrikan::Channel do
  describe "#enforce_operating_hours" do
    it "defaults to false" do
      channel = create_channel

      channel.enforce_operating_hours.should be_false
    end

    it "can be set to true" do
      channel = create_channel(enforce_operating_hours: true)

      channel.enforce_operating_hours.should be_true
    end
  end

  describe "#operating_hour_for" do
    it "returns the channel's own operating hour when set" do
      channel = create_channel
      op_hour = create_operating_hour(channel: channel, day: 1)

      channel.operating_hour_for(1).should eq op_hour
    end

    it "falls back to the space's operating hour when the channel has none" do
      space = create_space
      channel = create_channel(space: space)
      space_op_hour = create_operating_hour(space: space, day: 1)

      channel.operating_hour_for(1).should eq space_op_hour
    end

    it "returns nil when neither the channel nor its space has one" do
      channel = create_channel

      channel.operating_hour_for(1).should be_nil
    end
  end

  describe "#open_at?" do
    it "is true when no operating hours are configured anywhere" do
      channel = create_channel

      channel.open_at?(Time.utc(2026, 1, 26, 12, 0, 0)).should be_true
    end

    it "uses the channel's own hours when set" do
      channel = create_channel
      create_operating_hour(
        channel: channel,
        day: 0,
        open_time: Time::Span.new(hours: 14, minutes: 0),
        close_time: Time::Span.new(hours: 16, minutes: 0)
      )

      channel.open_at?(Time.utc(2026, 1, 26, 15, 0, 0)).should be_true
      channel.open_at?(Time.utc(2026, 1, 26, 9, 0, 0)).should be_false
    end

    it "converts Crystal's Sunday=7 day-of-week to this app's Sunday=6" do
      channel = create_channel
      create_operating_hour(
        channel: channel,
        day: 6,
        open_time: Time::Span.new(hours: 9, minutes: 0),
        close_time: Time::Span.new(hours: 17, minutes: 0)
      )

      # 2026-02-01 is a Sunday.
      channel.open_at?(Time.utc(2026, 2, 1, 12, 0, 0)).should be_true
    end
  end
end
