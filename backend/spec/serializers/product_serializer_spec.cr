require "../spec_helper"

describe ProductSerializer do
  describe ".serialize" do
    it "shows complete fields" do
      p = create_product(
        short_description: "shortdesc",
        note: "note"
      )

      json = JSON.parse ProductSerializer.serialize(p)
      json["id"].should eq p.hashed_id
      json["name"].should eq p.name
      json["short_description"].should eq p.short_description
      json["note"].should eq p.note
      json["created_at"].as_s.should match date_time_format
      json["updated_at"].as_s.should match date_time_format
      json["deleted_at"].should eq nil
    end
  end
end
