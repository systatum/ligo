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

    it "falls back to the parent channel's operating hour before the space's" do
      space = create_space
      parent = create_channel(space: space)
      sub_channel = create_channel(space: space, parent_channel: parent)
      parent_op_hour = create_operating_hour(channel: parent, day: 1)
      create_operating_hour(space: space, day: 1)

      sub_channel.operating_hour_for(1).should eq parent_op_hour
    end

    it "uses its own operating hour over the parent's when both are set" do
      space = create_space
      parent = create_channel(space: space)
      sub_channel = create_channel(space: space, parent_channel: parent)
      own_op_hour = create_operating_hour(channel: sub_channel, day: 1)
      create_operating_hour(channel: parent, day: 1)

      sub_channel.operating_hour_for(1).should eq own_op_hour
    end
  end

  describe "#parent_channel validations" do
    it "allows a sub-channel whose parent has no parent of its own" do
      space = create_space
      parent = create_channel(space: space)
      sub_channel = Antrikan::Channel.new
      sub_channel.space = space
      sub_channel.name = "Dr. Siti"
      sub_channel.parent_channel = parent

      sub_channel.valid?.should be_true
    end

    it "rejects a channel being its own parent" do
      channel = create_channel
      channel.parent_channel = channel

      channel.valid?.should be_false
      channel.errors[:parent_channel][0].message.should eq "cannot be its own parent"
    end

    it "rejects a parent channel from a different space" do
      other_space_parent = create_channel(space: create_space)
      channel = Antrikan::Channel.new
      channel.space = create_space
      channel.name = "Dr. Siti"
      channel.parent_channel = other_space_parent

      channel.valid?.should be_false
      channel.errors[:parent_channel][0].message.should eq "must belong to the same space"
    end

    it "rejects nesting a channel under a channel that is itself a sub-channel" do
      space = create_space
      grandparent = create_channel(space: space)
      parent = create_channel(space: space, parent_channel: grandparent)
      channel = Antrikan::Channel.new
      channel.space = space
      channel.name = "Too deep"
      channel.parent_channel = parent

      channel.valid?.should be_false
      channel.errors[:parent_channel][0].message.should eq(
        "cannot itself be a sub-channel (only one level of nesting is allowed)"
      )
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
