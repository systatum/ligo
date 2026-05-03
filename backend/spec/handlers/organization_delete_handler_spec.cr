require "../spec_helper"

describe OrganizationDeleteHandler do
  context "when the record to be deleted can be found" do
    it "will be soft-deleted" do
      o = create_organization
      o.deleted_at.should be_nil

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("auth:api_organization_delete", hashed_id: o.hashed_id),
      )

      response.status.should eq 200

      o_deleted = Auth::Organization.unscoped.get!(id: o.id)
      o_deleted.id.should eq o.id
      o_deleted.deleted_at.should_not be_nil

      response.content.should eq OrganizationSerializer.serialize(o_deleted)
    end
  end
end
