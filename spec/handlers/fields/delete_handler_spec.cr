require "../../spec_helper"

describe FieldDeleteHandler do
  it "soft deletes a field and returns serialized field" do
    user = create_user

    f = Ligo::FieldDefinition.new(
      name: "to_delete",
      resource_type: ResourceType::USER,
      data_type: FieldDataType::DTYPE_STRING.value.to_i64
    )
    f.save!

    response = Marten::Spec.client.post(
      Marten.routes.reverse("field_delete", field_hashed_id: f.hashed_id),
      headers: {authorization: "Bearer #{user.jwt_token}"},
      content_type: "application/json"
    )

    response.status.should eq 200

    f_deleted = Ligo::FieldDefinition.unscoped.get!(id: f.id)
    f_deleted.id.should eq f.id
    f_deleted.deleted_at.should be_a Time

    response.content.should eq FieldDefinitionSerializer.dump(f_deleted).to_json
  end
end
