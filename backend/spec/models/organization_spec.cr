require "../spec_helper"

describe Auth::Organization do
  describe ".get_by_hashed_id" do
    it "returns the record object if can be found or nil otherwise" do
      org = create_organization
      org.should_not be_nil

      found_org = Auth::Organization.get_by_hashed_id(org.hashed_id)
      found_org.should eq org

      not_found_org = Auth::Organization.get_by_hashed_id(IdConcealer.encode(1_000_000))
      not_found_org.should be_nil
    end
  end

  describe ".get_by_hashed_id!" do
    it "raises an error if the record can't be found" do
      org = create_organization
      org.should_not be_nil

      found_org = Auth::Organization.get_by_hashed_id!(org.hashed_id)
      found_org.should eq org

      expect_raises Marten::DB::Errors::RecordNotFound do
        found_org = Auth::Organization.get_by_hashed_id!(IdConcealer.encode(1_000_000))
      end
    end
  end
end
