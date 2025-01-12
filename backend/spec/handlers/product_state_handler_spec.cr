require "../spec_helper"

describe ProductStateHandler do
  describe "#show" do
    it "renders the fields" do
      prod = create_product

      response = Marten::Spec.client.get(
        Marten.routes.reverse("api_product_show", pk: prod.id!),
      )

      response.status.should eq 200
      response.content.should eq ProductSerializer.serialize(prod)
    end
  end

  describe "#patch" do
    context "when the product cannot be found" do
      it "renders 404" do
        response = Marten::Spec.client.patch(
          Marten.routes.reverse("api_product_update", pk: 123),
          data: {
            "short_description": "Wohoo",
          }.to_json,
          content_type: "application/json",
        )

        response.status.should be >= 400
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)
      end
    end

    context "when the product can be found" do
      it "can be updated accordingly" do
        new_org = create_organization
        new_name = "Night Wash"
        new_short_desc = "Night wash new cool"
        new_note = "This is very popular!"

        prod = create_product
        prod.organization_id.should_not eq new_org.id
        prod.name.should_not eq new_name
        prod.short_description.should_not eq new_short_desc
        prod.note.should_not eq new_note

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("api_product_update", pk: prod.id!),
          data: {
            organization_id:   new_org.id,
            name:              new_name,
            short_description: new_short_desc,
            note:              new_note,
          }.to_json,
          content_type: "application/json"
        )

        prod.reload
        prod.organization_id.should eq new_org.id
        prod.name.should eq new_name
        prod.short_description.should eq new_short_desc
        prod.note.should eq new_note

        response.status.should eq 200
        response.content.should eq ProductSerializer.serialize(prod)
      end
    end
  end

  describe "#delete" do
    context "when the record to be deleted can be found" do
      it "will be soft-deleted" do
        prod = create_product
        prod.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("api_product_delete", pk: prod.id!)
        )

        prod_deleted = Product.unscoped.get!(id: prod.id)
        prod_deleted.id.should eq prod.id
        prod_deleted.deleted_at.should_not be_nil

        response.content.should eq ProductSerializer.serialize(prod_deleted)
      end
    end
  end
end
