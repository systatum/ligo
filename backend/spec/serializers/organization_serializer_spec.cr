require "../spec_helper"

describe OrganizationSerializer do
  describe ".serialize" do
    context "when does not have timing fields set" do
      it "can be serialized" do
        json = JSON.parse OrganizationSerializer.serialize(Organization.new)
        json["id"].should eq nil
        json["name"].should eq nil
        json["created_at"].should eq nil
        json["updated_at"].should eq nil
        json["deleted_at"].should eq nil
      end
    end

    context "when the record has been serialized" do
      it "shows complete fields" do
        o = Organization.new(name: "MyOrg")
        o.save!

        json = JSON.parse OrganizationSerializer.serialize(o)
        json["id"].should eq 1
        json["name"].should eq "MyOrg"
        json["created_at"].as_s.should match date_time_format
        json["updated_at"].as_s.should match date_time_format
        json["deleted_at"].should eq nil
      end
    end

    context "when the record has been soft-deleted" do
      it "shows complete fields" do
        o = Organization.new(name: "MyOrg")
        o.save!
        o.soft_delete!

        json = JSON.parse OrganizationSerializer.serialize(o)
        json["id"].should eq 1
        json["name"].should eq "MyOrg"
        json["created_at"].as_s.should match date_time_format
        json["updated_at"].as_s.should match date_time_format
        json["deleted_at"].as_s.should match date_time_format
      end
    end
  end
end
