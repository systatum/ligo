require "../spec_helper"

describe FieldDefinitionSerializer do
  before_each do
    FieldDefinition.all.delete
  end

  describe ".dump" do
    it "dumps field definitions for a given resource type" do
      field = FieldDefinition.new(
        name: "test_field",
        resource_type: FieldResourceType::CANDIDATE,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: true,
        nullable: false,
        localized_name: LocalizedName.new(
          english: "Test Field",
          indonesian: "Bidang Tes",
          japanese: "テストフィールド"
        )
      )
      field.save!

      result = FieldDefinitionSerializer.dump(FieldResourceType::CANDIDATE)

      result.should be_a(Array(Hash(String, JSON::Any)))
      result.size.should eq 1

      field_data = result.first
      field_data["id"].as_s.should eq field.hashed_id
      field_data["native"].as_bool.should eq true
      field_data["type"].as_s.should eq "DTYPE_STRING"

      caption = field_data["caption"].as_h
      caption["en"].as_s.should eq "Test Field"
      caption["id"].as_s.should eq "Bidang Tes"
      caption["ja"].as_s.should eq "テストフィールド"
    end

    it "dumps fields using integer resource type" do
      field = FieldDefinition.new(
        name: "email",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false
      )
      field.save!

      result = FieldDefinitionSerializer.dump(1)

      result.size.should eq 1
      result.first["id"].as_s.should eq field.hashed_id
    end

    it "raises error for invalid resource type integer" do
      expect_raises(ArgumentError, /Invalid resource_type/) do
        FieldDefinitionSerializer.dump(999)
      end
    end

    it "returns empty array when no fields exist for resource type" do
      result = FieldDefinitionSerializer.dump(FieldResourceType::EMAIL_TEMPLATE)
      result.should be_a(Array(Hash(String, JSON::Any)))
      result.size.should eq 0
    end
  end
end
