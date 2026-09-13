require "../../spec_helper"

describe FieldIndexHandler do
  it "returns fields for a resource type" do
    f1 = Ligo::FieldDefinition.new(
      name: "username",
      resource_type: ResourceType::USER,
      data_type: FieldDataType::DTYPE_STRING.value.to_i64
    )
    f1.save!

    f2 = Ligo::FieldDefinition.new(
      name: "resume",
      resource_type: 500,
      data_type: FieldDataType::DTYPE_STRING.value.to_i64
    )
    f2.save!

    f3 = Ligo::FieldDefinition.new(
      name: "job",
      resource_type: ResourceType::USER,
      data_type: FieldDataType::DTYPE_STRING.value.to_i64
    )
    f3.save!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("field_index", resource_type: ResourceType::USER),
      content_type: "application/json"
    )

    response.status.should eq 200

    expected = {"fields" => [
      FieldDefinitionSerializer.dump(f1),
      FieldDefinitionSerializer.dump(f3),
    ]}
    response.content.should eq expected.to_json
  end
end
