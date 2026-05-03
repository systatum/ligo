require "../../spec_helper"

describe FieldCreateHandler do
  context "with only required fields" do
    it "should have the correct defaults" do
      user = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("field:create"),
        data: {
          name:          "new_field",
          resource_type: FieldResourceType::USER.to_s,
          data_type:     FieldDataType::DTYPE_STRING.to_s,
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      f = FieldDefinition.last!
      f.name.should eq "new_field"
      f.resource_type_enum.should eq FieldResourceType::USER
      f.data_type_enum.should eq FieldDataType::DTYPE_STRING
      f.localized_name.should eq nil
      f.nullable.should eq true
      f.uniqueness.should eq FieldUniqueness::UNIQUELESS
      f.metadata.should eq nil

      response.content.should eq FieldDefinitionSerializer.dump(f).to_json
    end
  end

  context "with optional fields" do
    it "should be set correctly" do
      user = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("field:create"),
        data: {
          name:           "new_choice_field",
          resource_type:  FieldResourceType::EMAIL_TEMPLATE.to_s,
          data_type:      FieldDataType::DTYPE_CHOICE_TOGGLE.to_s,
          localized_name: {english: "Choice", indonesian: "Pilihan"},
          nullable:       false,
          uniqueness:     FieldUniqueness::UNIQUE_ALWAYS.to_s,
          metadata:       {
            type:    "choice",
            options: [
              {id: "opt1", caption: {en: "One"}},
              {id: "opt2", caption: "Two"},
            ],
            default: "opt2",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      f = FieldDefinition.last!
      f.name.should eq "new_choice_field"
      f.resource_type_enum.should eq FieldResourceType::EMAIL_TEMPLATE
      f.data_type_enum.should eq FieldDataType::DTYPE_CHOICE_TOGGLE
      f.localized_name_english.should eq "Choice"
      f.localized_name_indonesian.should eq "Pilihan"
      f.nullable.should eq false
      f.uniqueness.should eq FieldUniqueness::UNIQUE_ALWAYS
      f.metadata.should be_a FieldMetadata::Choice

      response.content.should eq FieldDefinitionSerializer.dump(f).to_json
    end
  end
end
