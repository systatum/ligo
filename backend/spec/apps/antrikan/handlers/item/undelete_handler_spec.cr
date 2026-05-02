require "./spec_helper"

describe Antrikan::ItemUndeleteHandler do
  context "when the user is an admin" do
    it "restores a deleted item" do
      user = create_user
      item = create_item
      item.soft_delete!
      item_id = item.id!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:undelete", slug: item.slug!),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200

      restored = Antrikan::Item.get!(id: item_id)
      restored.deleted_at.should be_nil

      response.content.should eq Antrikan::ItemSerializer.serialize(restored)
    end
  end

  context "when the user is not an admin" do
    it "returns 403 and does not restore the item" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      item = create_item
      item.soft_delete!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:undelete", slug: item.slug!),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 403

      item_in_db = Antrikan::Item.unscoped.get!(id: item.id!)
      item_in_db.deleted_at.should_not be_nil
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      item = create_item
      item.soft_delete!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:undelete", slug: item.slug!)
      )

      response.status.should eq 400
    end
  end
end
