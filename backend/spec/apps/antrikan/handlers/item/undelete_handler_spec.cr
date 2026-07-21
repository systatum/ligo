require "./spec_helper"

describe Antrikan::ItemUndeleteHandler do
  context "when the user owns the item's space" do
    it "restores a deleted item" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
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

  context "when the user has an insufficient role and does not own the space" do
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

  context "when the user owns an unrelated space" do
    it "returns 403 and does not restore the item" do
      user = create_user
      create_space(manager: user)
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

  context "when the user has OWNER role in the same organization as the space owner" do
    it "restores the item" do
      organization = create_organization
      space_owner = create_user(organization: organization)
      space = create_space(manager: space_owner)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      item.soft_delete!
      colleague = create_user(organization: organization, role: Auth::Role::OWNER)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:undelete", slug: item.slug!),
        headers: {authorization: "Bearer #{colleague.jwt_token}"}
      )

      response.status.should eq 200

      item.reload
      item.deleted_at.should be_nil
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
