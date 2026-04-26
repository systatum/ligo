require "./spec_helper"

describe Antrikan::QueuerUndeleteHandler do
  describe "#patch" do
    context "when the user is an admin and owns the space" do
      it "restores a soft-deleted queuer" do
        user = create_user
        space = create_space(owner: user)
        queuer = create_queuer(space: space)
        queuer.soft_delete!
        queuer_id = queuer.id!

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:queuer:undelete", queuer_hashed_id: queuer.hashed_id),
          data: ({} of String => String).to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200

        restored = Antrikan::Queuer.get!(id: queuer_id)
        restored.deleted_at.should be_nil
        response.content.should eq Antrikan::QueuerSerializer.serialize(restored)
      end
    end

    context "when the user is an admin but does not own the space" do
      it "returns 403 and the queuer remains deleted" do
        owner = create_user
        admin = create_user
        space = create_space(owner: owner)
        queuer = create_queuer(space: space)
        queuer.soft_delete!

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:queuer:undelete", queuer_hashed_id: queuer.hashed_id),
          data: ({} of String => String).to_json,
          headers: {authorization: "Bearer #{admin.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 403

        still_deleted = Antrikan::Queuer.unscoped.get!(id: queuer.id!)
        still_deleted.deleted_at.should_not be_nil
      end
    end

    context "when the user is not an admin" do
      it "returns 403" do
        user = create_user(role: Auth::Role::SECURITY_STAFF)
        space = create_space(owner: user)
        queuer = create_queuer(space: space)
        queuer.soft_delete!

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:queuer:undelete", queuer_hashed_id: queuer.hashed_id),
          data: ({} of String => String).to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 403
      end
    end

    context "when the user is not authenticated" do
      it "returns 400" do
        queuer = create_queuer
        queuer.soft_delete!

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:queuer:undelete", queuer_hashed_id: queuer.hashed_id),
          data: ({} of String => String).to_json,
          content_type: "application/json"
        )

        response.status.should eq 400
      end
    end

    context "when the queuer does not exist" do
      it "returns 404" do
        user = create_user

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:queuer:undelete", queuer_hashed_id: IdConcealer.encode(999999999)),
          data: ({} of String => String).to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 404
      end
    end
  end
end
