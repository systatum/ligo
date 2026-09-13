require "../spec_helper"

describe FieldDefinitionSerializer do
  describe ".dump" do
    it "dumps a single field definition" do
      field = Ligo::FieldDefinition.new(
        name: "test_field",
        resource_type: 500,
        data_type: FieldDataType::DTYPE_STRING.value.to_i64,
        is_system_field: true,
        nullable: false,
        localized_name: LocalizedName.new(
          english: "Test Field",
          indonesian: "Bidang Tes",
          japanese: "テストフィールド"
        )
      )
      field.save!

      result = FieldDefinitionSerializer.dump(field)

      result.should be_a(Hash(String, JSON::Any))
      result["id"].as_s.should eq field.hashed_id
      result["native"].as_bool.should eq true
      result["type"].as_s.should eq "DTYPE_STRING"

      caption = result["caption"].as_h
      caption["en"].as_s.should eq "Test Field"
      caption["id"].as_s.should eq "Bidang Tes"
      caption["ja"].as_s.should eq "テストフィールド"
    end

    it "dumps minimal field definition" do
      field = Ligo::FieldDefinition.new(
        name: "email",
        resource_type: ResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING.value.to_i64,
        is_system_field: false
      )
      field.save!

      result = FieldDefinitionSerializer.dump(field)

      result["id"].as_s.should eq field.hashed_id
      result["native"].as_bool.should eq false
    end
  end
end
