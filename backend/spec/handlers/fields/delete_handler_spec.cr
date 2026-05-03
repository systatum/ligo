require "../../spec_helper"

describe FieldDeleteHandler do
  it "soft deletes a field and returns serialized field" do
    user = create_user

    f = FieldDefinition.new(
      name: "to_delete",
      resource_type: FieldResourceType::USER,
      data_type: FieldDataType::DTYPE_STRING
    )
    f.save!

    response = Marten::Spec.client.post(
      Marten.routes.reverse("field:delete", field_hashed_id: f.hashed_id),
      headers: {authorization: "Bearer #{user.jwt_token}"},
      content_type: "application/json"
    )

    response.status.should eq 200

    f_deleted = FieldDefinition.unscoped.get!(id: f.id)
    f_deleted.id.should eq f.id
    f_deleted.deleted_at.should be_a Time

    response.content.should eq FieldDefinitionSerializer.dump(f_deleted).to_json
  end
end
