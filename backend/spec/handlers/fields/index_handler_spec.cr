require "../../spec_helper"

describe FieldIndexHandler do
  it "returns fields for a resource type" do
    FieldDefinition.all.delete

    f1 = FieldDefinition.new(
      name: "username",
      resource_type: FieldResourceType::USER,
      data_type: FieldDataType::DTYPE_STRING
    )
    f1.save!

    f2 = FieldDefinition.new(
      name: "resume",
      resource_type: FieldResourceType::CANDIDATE,
      data_type: FieldDataType::DTYPE_STRING
    )
    f2.save!

    f3 = FieldDefinition.new(
      name: "job",
      resource_type: FieldResourceType::USER,
      data_type: FieldDataType::DTYPE_STRING
    )
    f3.save!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("field:index", resource_type: FieldResourceType::USER.to_s),
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
