require "../spec_helper"

describe Antrikan::Item do
  describe "#operating_hour_for" do
    it "returns the item's own operating hour when set" do
      item = create_item
      op_hour = create_operating_hour(item: item, day: 1)

      item.operating_hour_for(1).should eq op_hour
    end

    it "falls back to the channel's operating hour when the item has none" do
      channel = create_channel
      item = create_item(channel: channel)
      channel_op_hour = create_operating_hour(channel: channel, day: 1)

      item.operating_hour_for(1).should eq channel_op_hour
    end

    it "falls back through the channel to the space's operating hour" do
      space = create_space
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      space_op_hour = create_operating_hour(space: space, day: 1)

      item.operating_hour_for(1).should eq space_op_hour
    end

    it "returns nil when nothing in the hierarchy has one" do
      item = create_item

      item.operating_hour_for(1).should be_nil
    end
  end

  describe "#open_at?" do
    it "is true when no operating hours are configured anywhere" do
      item = create_item

      item.open_at?(Time.utc(2026, 1, 26, 12, 0, 0)).should be_true
    end

    it "uses the item's own hours over the channel's" do
      channel = create_channel
      item = create_item(channel: channel)
      create_operating_hour(
        channel: channel,
        day: 0,
        open_time: Time::Span.new(hours: 8, minutes: 0),
        close_time: Time::Span.new(hours: 17, minutes: 0)
      )
      create_operating_hour(
        item: item,
        day: 0,
        open_time: Time::Span.new(hours: 14, minutes: 0),
        close_time: Time::Span.new(hours: 16, minutes: 0)
      )

      item.open_at?(Time.utc(2026, 1, 26, 15, 0, 0)).should be_true
      item.open_at?(Time.utc(2026, 1, 26, 9, 0, 0)).should be_false
    end
  end
end
