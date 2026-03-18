require "../spec_helper"

describe Antrikan::Space do
  describe "#new" do
    context "when creating a space with default values" do
      it "sets default attributes" do
        user = create_user
        space = Antrikan::Space.new(
          owner: user,
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
          owner: user,
          name: "Test Space"
        )

        space.code.should_not be_nil
        space.code!.size.should eq 5
      end

      it "generates code using alphanumeric characters" do
        user = create_user
        space = Antrikan::Space.new(
          owner: user,
          name: "Test Space"
        )

        space.code!.each_char do |char|
          SlugGenerator::CHARACTER_SET.includes?(char).should be_true
        end
      end

      it "generates unique codes for different spaces" do
        user = create_user
        space1 = create_space(owner: user, name: "Space 1")
        space2 = create_space(owner: user, name: "Space 2")

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
          owner: user,
          name: ""
        )

        space.valid?.should be_false
        space.errors.first.field.should eq "name"
      end
    end

    context "when name is nil" do
      it "is invalid" do
        user = create_user
        space = Antrikan::Space.new(owner: user)

        space.valid?.should be_false
      end
    end

    context "when name is valid" do
      it "is valid" do
        user = create_user
        space = Antrikan::Space.new(
          owner: user,
          name: "Valid Space Name"
        )

        space.valid?.should be_true
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
end
