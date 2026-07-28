require "../spec_helper"

describe Antrikan::OperatingHour do
  describe "#new" do
    context "when creating with valid attributes" do
      it "creates an operating hour" do
        space = create_space
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end
    end
  end

  describe "#save" do
    context "when saving valid operating hours" do
      it "persists to the database" do
        op_hour = create_operating_hour

        op_hour.persisted?.should be_true
        op_hour.id.should_not be_nil
      end

      it "sets created_at and updated_at timestamps" do
        op_hour = create_operating_hour

        op_hour.created_at.should_not be_nil
        op_hour.updated_at.should_not be_nil
      end
    end
  end

  describe "validations" do
    describe "owner" do
      it "is invalid with no owner set" do
        op_hour = Antrikan::OperatingHour.new(
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_false
        op_hour.errors[:base].should_not be_empty
      end

      it "is invalid with more than one owner set" do
        space = create_space
        channel = create_channel(space: space)
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          channel: channel,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_false
        op_hour.errors[:base].should_not be_empty
      end

      it "is valid with only a channel set" do
        channel = create_channel
        op_hour = Antrikan::OperatingHour.new(
          channel: channel,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end

      it "is valid with only an item set" do
        item = create_item
        op_hour = Antrikan::OperatingHour.new(
          item: item,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end
    end

    describe "day range" do
      it "is valid with day 0 (Monday)" do
        op_hour = create_operating_hour(day: 0)
        op_hour.day.should eq 0
      end

      it "is valid with day 6 (Sunday)" do
        space = create_space
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: 6,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end

      it "is invalid with day less than 0" do
        space = create_space
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: -1,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_false
        op_hour.errors[:day].should_not be_empty
      end

      it "is invalid with day greater than 6" do
        space = create_space
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: 7,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_false
        op_hour.errors[:day].should_not be_empty
      end
    end

    describe "time format" do
      it "accepts Time::Span values for open and close times" do
        space = create_space
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end
    end

    describe "time range" do
      it "is invalid when close_time is before open_time" do
        space = create_space
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: 0,
          open_time: Time::Span.new(hours: 17, minutes: 0),
          close_time: Time::Span.new(hours: 9, minutes: 0)
        )

        op_hour.valid?.should be_false
        op_hour.errors[:close_time].should_not be_empty
      end

      it "is invalid when close_time equals open_time" do
        space = create_space
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 9, minutes: 0)
        )

        op_hour.valid?.should be_false
        op_hour.errors[:close_time].should_not be_empty
      end

      it "is valid when close_time is after open_time" do
        space = create_space
        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end
    end

    describe "uniqueness per day" do
      it "is invalid when same day exists for same space" do
        space = create_space
        create_operating_hour(space: space, day: 0)

        duplicate = Antrikan::OperatingHour.new
        duplicate.space = space
        duplicate.day = 0
        duplicate.open_time = Time::Span.new(hours: 10, minutes: 0)
        duplicate.close_time = Time::Span.new(hours: 18, minutes: 0)

        duplicate.valid?.should be_false
        duplicate.errors[:day].should_not be_empty
      end

      it "is valid when same day exists for different space" do
        space1 = create_space
        space2 = create_space

        create_operating_hour(space: space1, day: 0)

        op_hour = Antrikan::OperatingHour.new(
          space: space2,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end

      it "is valid when different day exists for same space" do
        space = create_space
        create_operating_hour(space: space, day: 0)

        op_hour = Antrikan::OperatingHour.new(
          space: space,
          day: 1,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end

      it "is invalid when same day exists for same channel" do
        channel = create_channel
        create_operating_hour(channel: channel, day: 0)

        duplicate = Antrikan::OperatingHour.new(
          channel: channel,
          day: 0,
          open_time: Time::Span.new(hours: 10, minutes: 0),
          close_time: Time::Span.new(hours: 18, minutes: 0)
        )

        duplicate.valid?.should be_false
        duplicate.errors[:day].should_not be_empty
      end

      it "is valid when same day exists for different channel" do
        channel1 = create_channel
        channel2 = create_channel
        create_operating_hour(channel: channel1, day: 0)

        op_hour = Antrikan::OperatingHour.new(
          channel: channel2,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end

      it "is invalid when same day exists for same item" do
        item = create_item
        create_operating_hour(item: item, day: 0)

        duplicate = Antrikan::OperatingHour.new(
          item: item,
          day: 0,
          open_time: Time::Span.new(hours: 10, minutes: 0),
          close_time: Time::Span.new(hours: 18, minutes: 0)
        )

        duplicate.valid?.should be_false
        duplicate.errors[:day].should_not be_empty
      end

      it "is valid when same day exists for different item" do
        item1 = create_item
        item2 = create_item
        create_operating_hour(item: item1, day: 0)

        op_hour = Antrikan::OperatingHour.new(
          item: item2,
          day: 0,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        op_hour.valid?.should be_true
      end
    end
  end

  describe "#open_at?" do
    it "returns true when time is within operating hours" do
      op_hour = create_operating_hour(
        open_time: Time::Span.new(hours: 9, minutes: 0),
        close_time: Time::Span.new(hours: 17, minutes: 0)
      )

      op_hour.open_at?(Time.utc(2026, 1, 29, 12, 0, 0)).should be_true
    end

    it "returns false when time is before open_time" do
      op_hour = create_operating_hour(
        open_time: Time::Span.new(hours: 9, minutes: 0),
        close_time: Time::Span.new(hours: 17, minutes: 0)
      )

      op_hour.open_at?(Time.utc(2026, 1, 29, 8, 0, 0)).should be_false
    end

    it "returns false when time is at or after close_time" do
      op_hour = create_operating_hour(
        open_time: Time::Span.new(hours: 9, minutes: 0),
        close_time: Time::Span.new(hours: 17, minutes: 0)
      )

      op_hour.open_at?(Time.utc(2026, 1, 29, 17, 0, 0)).should be_false
      op_hour.open_at?(Time.utc(2026, 1, 29, 18, 0, 0)).should be_false
    end

    it "returns true at exactly open_time" do
      op_hour = create_operating_hour(
        open_time: Time::Span.new(hours: 9, minutes: 0),
        close_time: Time::Span.new(hours: 17, minutes: 0)
      )

      op_hour.open_at?(Time.utc(2026, 1, 29, 9, 0, 0)).should be_true
    end
  end

  describe "Day enum" do
    it "defines correct day values" do
      Antrikan::OperatingHour::Day::MONDAY.value.should eq 0
      Antrikan::OperatingHour::Day::TUESDAY.value.should eq 1
      Antrikan::OperatingHour::Day::WEDNESDAY.value.should eq 2
      Antrikan::OperatingHour::Day::THURSDAY.value.should eq 3
      Antrikan::OperatingHour::Day::FRIDAY.value.should eq 4
      Antrikan::OperatingHour::Day::SATURDAY.value.should eq 5
      Antrikan::OperatingHour::Day::SUNDAY.value.should eq 6
    end
  end
end
