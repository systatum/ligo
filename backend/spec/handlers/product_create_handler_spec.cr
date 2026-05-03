require "../spec_helper"

describe ProductCreateHandler do
  context "when minimum required fields are given" do
    it "creates a new product" do
      user = create_user
      response = Marten::Spec.client.post(
        Marten.routes.reverse("api_product_create"),
        data: {name: "Created Prod"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      prod = Product.last!
      prod.organization.should eq user.organization
      prod.name.should eq "Created Prod"
      prod.short_description.should eq ""
      prod.created_at.should_not be_nil
      prod.updated_at.should_not be_nil

      response.content.should eq ProductSerializer.serialize(prod)
    end

    it "sets the performer_id on the changelog entry" do
      user = create_user
      response = Marten::Spec.client.post(
        Marten.routes.reverse("api_product_create"),
        data: {name: "Created Prod"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      prod = Product.last!
      changelog = Changelog.filter(
        record_class: "Product",
        record_id: prod.id,
        action_type: Changelog::ActionType::CREATE
      ).first!

      changelog.performer_id.should_not be_nil
      changelog.performer_id.should eq user.id
    end
  end
end
