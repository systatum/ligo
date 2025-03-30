require "../spec_helper"

describe OrganizationSerializer do
  describe ".serialize" do
    context "when does not have timing fields set" do
      it "can be serialized" do
        o = create_organization
        o.created_at = nil
        o.deleted_at = nil
        o.updated_at = nil

        json = JSON.parse OrganizationSerializer.serialize(o)
        json["created_at"].should eq nil
        json["updated_at"].should eq nil
        json["deleted_at"].should eq nil
      end
    end

    context "when the record has been serialized" do
      it "shows complete fields" do
        o = Auth::Organization.new(name: "MyOrg")
        o.save!

        json = JSON.parse OrganizationSerializer.serialize(o)
        json["id"].should eq o.hashed_id
        json["name"].should eq "MyOrg"
        json["created_at"].as_s.should match date_time_format
        json["updated_at"].as_s.should match date_time_format
        json["deleted_at"].should eq nil
      end
    end

    context "when the record has been soft-deleted" do
      it "shows complete fields" do
        o = Auth::Organization.new(name: "MyOrg")
        o.save!
        o.soft_delete!

        json = JSON.parse OrganizationSerializer.serialize(o)
        json["id"].should eq o.hashed_id
        json["name"].should eq "MyOrg"
        json["created_at"].as_s.should match date_time_format
        json["updated_at"].as_s.should match date_time_format
        json["deleted_at"].as_s.should match date_time_format
      end
    end
  end
end
