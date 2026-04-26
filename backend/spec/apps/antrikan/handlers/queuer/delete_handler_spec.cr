require "./spec_helper"

describe Antrikan::QueuerDeleteHandler do
  describe "#delete" do
    context "when the user is an admin and owns the space" do
      it "soft-deletes the queuer" do
        user = create_user
        space = create_space(owner: user)
        queuer = create_queuer(space: space)
        queuer_id = queuer.id!

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:queuer:delete", queuer_hashed_id: queuer.hashed_id),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 200

        deleted = Antrikan::Queuer.unscoped.get!(id: queuer_id)
        deleted.deleted_at.should be_a Time
        response.content.should eq Antrikan::QueuerSerializer.serialize(deleted)
      end
    end

    context "when the user is an admin but does not own the space" do
      it "returns 403 and does not delete the queuer" do
        owner = create_user
        admin = create_user
        space = create_space(owner: owner)
        queuer = create_queuer(space: space)

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:queuer:delete", queuer_hashed_id: queuer.hashed_id),
          headers: {authorization: "Bearer #{admin.jwt_token}"}
        )

        response.status.should eq 403

        queuer.reload
        queuer.deleted_at.should be_nil
      end
    end

    context "when the user is not an admin" do
      it "returns 403 and does not delete the queuer" do
        user = create_user(role: Auth::Role::SECURITY_STAFF)
        space = create_space(owner: user)
        queuer = create_queuer(space: space)

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:queuer:delete", queuer_hashed_id: queuer.hashed_id),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 403

        queuer.reload
        queuer.deleted_at.should be_nil
      end
    end

    context "when the user is not authenticated" do
      it "returns 400" do
        queuer = create_queuer

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:queuer:delete", queuer_hashed_id: queuer.hashed_id)
        )

        response.status.should eq 400
      end
    end

    context "when the queuer does not exist" do
      it "returns 404" do
        user = create_user

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("antrikan:queuer:delete", queuer_hashed_id: IdConcealer.encode(999999999)),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 404
      end
    end
  end
end
