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
  end

  describe "soft delete" do
    it "supports soft deletion" do
      review = create_space_review

      review.soft_delete!
      review.deleted_at.should_not be_nil
    end
  end
end
