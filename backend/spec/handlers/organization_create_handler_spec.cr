require "../spec_helper"

describe OrganizationCreateHandler do
  describe "#post" do
    context "when minimum required fields are given" do
      it "creates a new organization" do
        response = Marten::Spec.client.post(
          Marten.routes.reverse("auth:api_organization_create"),
          data: {
            name: "Created Org",
          }.to_json,
          content_type: "application/json"
        )
        org = Auth::Organization.last!
        org.name.should eq "Created Org"

        response.status.should eq 200
        response.content.should eq OrganizationSerializer.serialize(org)
      end
    end
  end
end
