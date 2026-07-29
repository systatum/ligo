require "../spec_helper"

describe Antrikan::Business do
  describe "#save" do
    it "persists name and owner" do
      owner = create_user
      business = create_business(owner: owner, name: "Acme Coffee Co")

      business.name.should eq "Acme Coffee Co"
      business.owner_id.should eq owner.id
    end
  end

  describe "soft delete" do
    it "supports soft deletion" do
      business = create_business

      business.soft_delete!
      business.deleted_at.should_not be_nil
    end
  end
end
