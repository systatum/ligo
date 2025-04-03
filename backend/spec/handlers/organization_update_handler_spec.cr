require "../spec_helper"

describe OrganizationUpdateHandler do
  describe "#patch" do
    context "when the organization cannot be found" do
      it "renders 404" do
        response = Marten::Spec.client.patch(
          Marten.routes.reverse("auth:api_organization_update", hashed_id: "123"),
          data: {
            name: "Updated Org",
          }.to_json,
          content_type: "application/json",
        )

        response.status.should eq 404
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)
      end
    end

    context "when the organization can be found" do
      it "can update accordingly" do
        o = create_organization
        o.name.should_not eq "Updated Org"

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("auth:api_organization_update", hashed_id: o.hashed_id),
          data: {
            name: "Updated Org",
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 200

        o.reload
        o.name.should eq "Updated Org"

        response.content.should eq OrganizationSerializer.serialize(o)
      end
    end

    context "when given unpermitted fields" do
      it "won't be updated" do
        o = create_organization

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("auth:api_organization_update", hashed_id: o.hashed_id),
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
end
