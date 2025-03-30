require "../spec_helper"

describe ProductCreateHandler do
  describe "#post" do
    context "when minimum required fields are given" do
      it "creates a new product" do
        user = create_user
        response = Marten::Spec.client.post(
          Marten.routes.reverse("api_product_create"),
          data: {name: "Created Prod"}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )
        prod = Product.last!
        prod.organization.should eq user.organization
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
