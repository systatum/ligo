require "../spec_helper"

describe ProductCreateHandler do
  describe "#post" do
    context "when minimum required fields are given" do
      it "creates a new product" do
        org = create_organization
        response = Marten::Spec.client.post(
          Marten.routes.reverse("api_product_create"),
          data: {
            organization_id: org.id,
            name:            "Created Prod",
          }.to_json,
          content_type: "application/json"
        )
        prod = Product.last!
        prod.organization.should eq org
        prod.name.should eq "Created Prod"
        prod.short_description.should eq ""
        prod.created_at.should_not be_nil
        prod.updated_at.should_not be_nil

        response.status.should eq 200
        response.content.should eq ProductSerializer.serialize(prod)
      end
    end
  end
end
