require "./spec_helper"

describe Antrikan::VoucherDeleteHandler do
  context "when the user owns the voucher's space" do
    it "soft deletes the voucher" do
      user = create_user
      space = create_space(manager: user)
      voucher = create_voucher(space: space)
      voucher_id = voucher.id!

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:voucher:delete", voucher_hashed_id: voucher.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200

      deleted_voucher = Antrikan::Voucher.unscoped.get!(id: voucher_id)
      deleted_voucher.deleted_at.should_not be_nil

      response.content.should eq Antrikan::VoucherSerializer.serialize(deleted_voucher)
    end
  end

  context "when the user does not own the voucher's space" do
    it "returns 403 and does not delete the voucher" do
      voucher = create_voucher
      other_user = create_user

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:voucher:delete", voucher_hashed_id: voucher.hashed_id),
        headers: {authorization: "Bearer #{other_user.jwt_token}"}
      )

      response.status.should eq 403

      voucher.reload
      voucher.deleted_at.should be_nil
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      voucher = create_voucher

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("antrikan:voucher:delete", voucher_hashed_id: voucher.hashed_id)
      )

      response.status.should eq 400
    end
  end
end
