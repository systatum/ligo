require "../../spec_helper"

describe FieldUpdateHandler do
  context "with only required fields" do
    it "should be updated just fine" do
      user = create_user

      f = Ligo::FieldDefinition.new(
        name: "to_update",
        resource_type: ResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING.value.to_i64
      )
      f.save!

      response = Marten::Spec.client.post(
        Marten.routes.reverse("field_update", field_hashed_id: f.hashed_id),
        data: {
          name:          "updated_name",
          resource_type: 500,
          data_type:     FieldDataType::DTYPE_STRING.to_s,
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      f.reload
      f.name.should eq "updated_name"
      f.resource_type.should eq 500
      f.data_type_enum.should eq FieldDataType::DTYPE_STRING

      response.content.should eq FieldDefinitionSerializer.dump(f).to_json
    end
  end

  context "with optional fields" do
    it "should update all just fine" do
      user = create_user

      f = Ligo::FieldDefinition.new(
        name: "to_update",
        resource_type: 500,
        data_type: FieldDataType::DTYPE_STRING.value.to_i64
      )
      f.save!

      response = Marten::Spec.client.post(
        Marten.routes.reverse("field_update", field_hashed_id: f.hashed_id),
        data: {
          name:           "updated_name",
          resource_type:  500,
          data_type:      FieldDataType::DTYPE_CHOICE_TOGGLE.to_s,
          localized_name: {english: "Updated", indonesian: "Diperbarui"},
          nullable:       false,
          uniqueness:     FieldUniqueness::UNIQUE_FILL.to_s,
          metadata:       {
            type:    "choice",
            options: [{id: "a", caption: {en: "A"}}, {id: "b", caption: "B"}],
            default: "a",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      f.reload
      f.name.should eq "updated_name"
      f.localized_name_english.should eq "Updated"
      f.localized_name_indonesian.should eq "Diperbarui"
      f.nullable.should eq false
      f.uniqueness.should eq FieldUniqueness::UNIQUE_FILL
      f.metadata.should be_a FieldMetadata::Choice

      response.content.should eq FieldDefinitionSerializer.dump(f).to_json
    end
  end
end
