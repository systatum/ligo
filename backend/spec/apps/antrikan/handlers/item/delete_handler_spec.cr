require "./spec_helper"

describe Antrikan::ItemDeleteHandler do
  context "when the user owns the item's space" do
    it "soft deletes the item" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
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

  context "when the user has an insufficient role and does not own the space" do
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

  context "when the user owns an unrelated space" do
    it "returns 403 and does not delete the item" do
      user = create_user
      create_space(manager: user)
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

  context "when the user has OWNER role in the same organization as the space owner" do
    it "deletes the item" do
      organization = create_organization
      space_owner = create_user(organization: organization)
      space = create_space(manager: space_owner)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      item_id = item.id!
      colleague = create_user(organization: organization, role: Auth::Role::OWNER)

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:item:delete", slug: item.slug!),
        headers: {authorization: "Bearer #{colleague.jwt_token}"}
      )

      response.status.should eq 200

      deleted = Antrikan::Item.unscoped.get!(id: item_id)
      deleted.deleted_at.should be_a Time
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
