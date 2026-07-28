require "../spec_helper"

describe Antrikan::Space do
  describe "#new" do
    context "when creating a space with default values" do
      it "sets default attributes" do
        user = create_user
        space = Antrikan::Space.new(
          manager: user,
          name: "Test Space"
        )

        space.need_manual_approval.should be_true
        space.has_operating_hours.should be_false
      end
    end

    context "when auto-generating code on create" do
      it "generates a 5-character code" do
        user = create_user
        space = Antrikan::Space.new(
          manager: user,
          name: "Test Space"
        )

        space.code.should_not be_nil
        space.code!.size.should eq 5
      end

      it "generates code using alphanumeric characters" do
        user = create_user
        space = Antrikan::Space.new(
          manager: user,
          name: "Test Space"
        )

        space.code!.each_char do |char|
          SlugGenerator::CHARACTER_SET.includes?(char).should be_true
        end
      end

      it "generates unique codes for different spaces" do
        user = create_user
        space1 = create_space(manager: user, name: "Space 1")
        space2 = create_space(manager: user, name: "Space 2")

        space1.code.should_not eq space2.code
      end
    end
  end

  describe "#save" do
    context "when saving a valid space" do
      it "sets created_at and updated_at timestamps" do
        space = create_space

        space.created_at.should_not be_nil
        space.updated_at.should_not be_nil
      end
    end

    context "when saving with custom values" do
      it "persists need_manual_approval as false" do
        space = create_space(need_manual_approval: false)

        space.need_manual_approval.should be_false
      end

      it "persists has_operating_hours as true" do
        space = create_space(has_operating_hours: true)

        space.has_operating_hours.should be_true
      end
    end
  end

  describe "validations" do
    context "when name is blank" do
      it "is invalid" do
        user = create_user
        space = Antrikan::Space.new(
          manager: user,
          owner: create_business(owner: user),
          name: ""
        )

        space.valid?.should be_false
        space.errors.first.field.should eq "name"
      end
    end

    context "when name is nil" do
      it "is invalid" do
        user = create_user
        space = Antrikan::Space.new(manager: user, owner: create_business(owner: user))

        space.valid?.should be_false
      end
    end

    context "when name is valid" do
      it "is valid" do
        user = create_user
        space = Antrikan::Space.new(
          manager: user,
          owner: create_business(owner: user),
          name: "Valid Space Name"
        )

        space.valid?.should be_true
      end
    end

    context "address_city_code" do
      it "is valid when not provided" do
        space = create_space(address_city_code: nil)

        space.valid?.should be_true
      end

      it "is valid with a known city entry" do
        space = Antrikan::Space.new(
          manager: create_user,
          owner: create_business,
          name: "Valid Space Name",
          address_city_code: 100_160_007 # Bogor, West Java - data/countries/100_IDN.json
        )

        space.valid?.should be_true
      end

      it "is invalid when the country code prefix matches no file" do
        space = Antrikan::Space.new(
          manager: create_user,
          owner: create_business,
          name: "Valid Space Name",
          address_city_code: 999_160_007
        )

        space.valid?.should be_false
        space.errors[:address_city_code].should_not be_empty
      end

      it "is invalid when the country code is known but the city id doesn't exist" do
        space = Antrikan::Space.new(
          manager: create_user,
          owner: create_business,
          name: "Valid Space Name",
          address_city_code: 100_999_999
        )

        space.valid?.should be_false
        space.errors[:address_city_code].should_not be_empty
      end
    end
  end

  describe "#filter_by_code" do
    it "finds space by code" do
      space = create_space

      found = Antrikan::Space.filter_by_code(space.code!).first
      found.should_not be_nil
      found.not_nil!.id.should eq space.id
    end

    it "returns empty when code not found" do
      Antrikan::Space.filter_by_code("XXXXX").exists?.should be_false
    end
  end

  describe "soft delete" do
    it "supports soft deletion" do
      space = create_space

      space.soft_delete!
      space.deleted_at.should_not be_nil
    end
  end

  describe "#owned_by?" do
    it "is true for the space's manager" do
      manager = create_user
      space = create_space(manager: manager)

      space.owned_by?(manager).should be_true
    end

    it "is true for the space's business owner, even if not the manager" do
      manager = create_user
      business_owner = create_user
      business = create_business(owner: business_owner)
      space = create_space(manager: manager, business: business)

      space.owned_by?(business_owner).should be_true
    end

    it "is true for a same-organization OWNER-role user" do
      organization = create_organization
      manager = create_user(organization: organization)
      space = create_space(manager: manager)
      colleague = create_user(organization: organization, role: Auth::Role::OWNER)

      space.owned_by?(colleague).should be_true
    end

    it "is false for an unrelated user" do
      space = create_space
      unrelated_user = create_user

      space.owned_by?(unrelated_user).should be_false
    end
  end

  describe "#staffed_by?" do
    it "is true for anyone owned_by? already covers" do
      manager = create_user
      space = create_space(manager: manager)

      space.staffed_by?(manager).should be_true
    end

    it "is true for a same-organization admin-tier user below OWNER" do
      organization = create_organization
      manager = create_user(organization: organization)
      space = create_space(manager: manager)
      colleague = create_user(organization: organization, role: Auth::Role::OPERATION_STAFF)

      space.staffed_by?(colleague).should be_true
    end

    it "is false for a same-organization user below the admin tier" do
      organization = create_organization
      manager = create_user(organization: organization)
      space = create_space(manager: manager)
      colleague = create_user(organization: organization, role: Auth::Role::STAFF)

      space.staffed_by?(colleague).should be_false
    end

    it "is false for an admin-tier user from a different organization" do
      space = create_space
      outsider = create_user(role: Auth::Role::OPERATION_STAFF)

      space.staffed_by?(outsider).should be_false
    end
  end

  describe "#average_rating and #review_count" do
    it "returns 0.0 and 0 when there are no reviews" do
      space = create_space

      space.average_rating.should eq 0.0
      space.review_count.should eq 0
    end

    it "computes the average and count fresh from current reviews" do
      space = create_space
      create_space_review(space: space, reviewer: create_user, rating: 4.0)
      create_space_review(space: space, reviewer: create_user, rating: 8.0)

      space.average_rating.should eq 6.0
      space.review_count.should eq 2
    end

    it "excludes soft-deleted reviews" do
      space = create_space
      create_space_review(space: space, reviewer: create_user, rating: 4.0)
      deleted_review = create_space_review(space: space, reviewer: create_user, rating: 10.0)
      deleted_review.soft_delete!

      space.average_rating.should eq 4.0
      space.review_count.should eq 1
    end

    it "reflects an update to a review's rating immediately" do
      space = create_space
      review = create_space_review(space: space, reviewer: create_user, rating: 4.0)

      review.rating = 10.0
      review.save!

      space.average_rating.should eq 10.0
    end

    it "does not include reviews from other spaces" do
      space = create_space
      other_space = create_space
      create_space_review(space: other_space, reviewer: create_user, rating: 2.0)

      space.average_rating.should eq 0.0
      space.review_count.should eq 0
    end
  end

  describe "#operating_hour_for" do
    it "returns the operating hour for that day" do
      space = create_space
      op_hour = create_operating_hour(space: space, day: 1)

      space.operating_hour_for(1).should eq op_hour
    end

    it "returns nil when no operating hour is configured for that day" do
      space = create_space
      create_operating_hour(space: space, day: 1)

      space.operating_hour_for(2).should be_nil
    end
  end
end
