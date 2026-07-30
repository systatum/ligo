require "../spec_helper"

describe Antrikan::SpaceReview do
  describe "validations" do
    context "when rating is within 0.0..10.0" do
      it "is valid" do
        review = Antrikan::SpaceReview.new(space: create_space, reviewer: create_user, rating: 7.5)
        review.valid?.should be_true
      end
    end

    context "when rating is below 0.0" do
      it "is invalid" do
        review = Antrikan::SpaceReview.new(space: create_space, reviewer: create_user, rating: -0.1)
        review.valid?.should be_false
        review.errors.first.field.should eq "rating"
      end
    end

    context "when rating is above 10.0" do
      it "is invalid" do
        review = Antrikan::SpaceReview.new(space: create_space, reviewer: create_user, rating: 10.1)
        review.valid?.should be_false
        review.errors.first.field.should eq "rating"
      end
    end

    context "when the same user already reviewed the space" do
      it "is invalid" do
        space = create_space
        reviewer = create_user
        create_space_review(space: space, reviewer: reviewer)

        review = Antrikan::SpaceReview.new(space: space, reviewer: reviewer, rating: 5.0)
        review.valid?.should be_false
      end
    end

    context "when reviewer is nil" do
      it "is valid" do
        review = Antrikan::SpaceReview.new(space: create_space, reviewer: nil, rating: 6.0)
        review.valid?.should be_true
      end
    end

    context "when only channel is set" do
      it "is valid when the channel belongs to the same space" do
        space = create_space
        channel = create_channel(space: space)
        review = Antrikan::SpaceReview.new(space: space, reviewer: create_user, rating: 7.0, channel: channel)

        review.valid?.should be_true
      end

      it "is invalid when the channel belongs to a different space" do
        space = create_space
        other_channel = create_channel
        review = Antrikan::SpaceReview.new(space: space, reviewer: create_user, rating: 7.0, channel: other_channel)

        review.valid?.should be_false
        review.errors[:channel][0].message.should eq "must belong to the same space as the review"
      end
    end

    context "when only item is set" do
      it "is valid when the item's channel belongs to the same space" do
        space = create_space
        channel = create_channel(space: space)
        item = create_item(channel: channel)
        review = Antrikan::SpaceReview.new(space: space, reviewer: create_user, rating: 7.0, item: item)

        review.valid?.should be_true
      end

      it "is invalid when the item's channel belongs to a different space" do
        space = create_space
        other_item = create_item
        review = Antrikan::SpaceReview.new(space: space, reviewer: create_user, rating: 7.0, item: other_item)

        review.valid?.should be_false
        review.errors[:item][0].message.should eq "must belong to the same space as the review"
      end
    end

    context "when both channel and item are set" do
      it "is invalid" do
        space = create_space
        channel = create_channel(space: space)
        item = create_item(channel: channel)
        review = Antrikan::SpaceReview.new(
          space: space, reviewer: create_user, rating: 7.0, channel: channel, item: item
        )

        review.valid?.should be_false
        review.errors[:item][0].message.should eq "cannot be set together with channel"
      end
    end
  end

  describe "soft delete" do
    it "supports soft deletion" do
      review = create_space_review

      review.soft_delete!
      review.deleted_at.should_not be_nil
    end
  end
end
