require "../spec_helper"

describe ProductStateHandler do
  describe "#show" do
    it "renders the fields" do
      user = create_user
      prod = create_product organization: user.organization

      response = Marten::Spec.client.get(
        Marten.routes.reverse("api_product_show", id: prod.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json",
      )

      response.status.should eq 200
      response.content.should eq ProductSerializer.serialize(prod)
    end
  end

  context "when the product cannot be found" do
    it "renders 404" do
      user = create_user
      response = Marten::Spec.client.patch(
        Marten.routes.reverse("api_product_update", id: "123"),
        data: {"short_description": "Wohoo"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json",
      )

      response.status.should be >= 400
      response.content.should eq({error: {messages: ["Not found"]}}.to_json)
    end
  end

  context "when the product can be found" do
    context "when not an admin" do
      it "cannot update the organization ID" do
        user = create_user
        prod = create_product

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("api_product_update", id: prod.hashed_id),
          data: {
            name: "Test",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 404
      end
    end

    context "when a super admin" do
      it "can be updated accordingly" do
        user = create_user

        # sign in as admin user
        new_name = "Night Wash"
        new_short_desc = "Night wash new cool"
        new_note = "This is very popular!"

        prod = create_product organization: user.organization
        prod.name.should_not eq new_name
        prod.short_description.should_not eq new_short_desc
        prod.note.should_not eq new_note

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("api_product_update", id: prod.hashed_id),
          data: {
            name:              new_name,
            short_description: new_short_desc,
            note:              new_note,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        prod.reload
        response.status.should eq 200
        response.content.should eq ProductSerializer.serialize(prod)

        prod.organization.should eq user.organization
        prod.name.should eq new_name
        prod.short_description.should eq new_short_desc
        prod.note.should eq new_note
      end
    end
  end

  context "when the record to be deleted can be found" do
    it "will be soft-deleted" do
      user = create_user
      prod = create_product organization: user.organization
      prod.deleted_at.should be_nil

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("api_product_delete", id: prod.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"},
      )

      prod_deleted = Product.unscoped.get!(id: prod.id)
      prod_deleted.id.should eq prod.id
      prod_deleted.deleted_at.should_not be_nil

      response.content.should eq ProductSerializer.serialize(prod_deleted)
    end
  end
end
