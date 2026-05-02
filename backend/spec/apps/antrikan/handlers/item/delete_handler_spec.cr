require "./spec_helper"

describe Antrikan::ItemDeleteHandler do
  context "when the user is an admin" do
    it "soft deletes the item" do
      user = create_user
      item = create_item
      item_id = item.id!

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:item:delete", slug: item.slug!),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200

      deleted = Antrikan::Item.unscoped.get!(id: item_id)
      deleted.deleted_at.should be_a Time

      response.content.should eq Antrikan::ItemSerializer.serialize(deleted)
    end
  end

  context "when the user is not an admin" do
    it "returns 403 and does not delete the item" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      item = create_item

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:item:delete", slug: item.slug!),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 403

      item.reload
      item.deleted_at.should be_nil
    end
  end

  context "when the user is not authenticated" do
    it "returns 400 and does not delete the item" do
      item = create_item

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:item:delete", slug: item.slug!)
      )

      response.status.should eq 400

      item.reload
      item.deleted_at.should be_nil
    end
  end
end
