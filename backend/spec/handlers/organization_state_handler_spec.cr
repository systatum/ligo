require "../spec_helper"

describe OrganizationStateHandler do
  describe "#patch" do
    context "when the organization cannot be found" do
      it "renders 404" do
        response = Marten::Spec.client.patch(
          Marten.routes.reverse("auth:api_organization_update", pk: 123),
          data: {
            name: "Updated Org",
          }.to_json,
          content_type: "application/json",
        )

        response.status.should be >= 400
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)
      end
    end

    context "when the organization can be found" do
      it "can update accordingly" do
        o = create_organization
        o.name.should_not eq "Updated Org"

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("auth:api_organization_update", pk: o.id!),
          data: {
            name: "Updated Org",
          }.to_json,
          content_type: "application/json"
        )

        o.reload
        o.name.should eq "Updated Org"

        response.status.should eq 200
        response.content.should eq OrganizationSerializer.serialize(o)
      end
    end

    context "when given unpermitted fields" do
      it "won't be updated" do
        o = create_organization

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("auth:api_organization_update", pk: o.id!),
          data: {
            id: 1,
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 400
        response.content.should eq({error: {messages: ["Invalid payload"]}}.to_json)
      end
    end
  end

  describe "#delete" do
    context "when the record to be deleted can be found" do
      it "will be soft-deleted" do
        o = create_organization
        o.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("auth:api_organization_delete", pk: o.id!),
        )

        o_deleted = Auth::Organization.unscoped.get!(id: o.id)
        o_deleted.id.should eq o.id
        o_deleted.deleted_at.should_not be_nil

        response.content.should eq OrganizationSerializer.serialize(o_deleted)
      end
    end
  end
end
