require "./spec_helper"

describe Antrikan::VoucherUndeleteHandler do
  context "when the user owns the voucher's space" do
    it "restores a deleted voucher" do
      user = create_user
      space = create_space(manager: user)
      voucher = create_voucher(space: space)
      voucher.soft_delete!
      voucher_id = voucher.id!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:voucher:undelete", voucher_hashed_id: voucher.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200

      restored = Antrikan::Voucher.get!(id: voucher_id)
      restored.deleted_at.should be_nil

      response.content.should eq Antrikan::VoucherSerializer.serialize(restored)
    end
  end

  context "when the user does not own the voucher's space" do
    it "returns 403 and does not restore the voucher" do
      voucher = create_voucher
      voucher.soft_delete!
      other_user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:voucher:undelete", voucher_hashed_id: voucher.hashed_id),
        headers: {authorization: "Bearer #{other_user.jwt_token}"}
      )

      response.status.should eq 403

      voucher_in_db = Antrikan::Voucher.unscoped.get!(id: voucher.id!)
      voucher_in_db.deleted_at.should_not be_nil
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      voucher = create_voucher
      voucher.soft_delete!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:voucher:undelete", voucher_hashed_id: voucher.hashed_id)
      )

      response.status.should eq 400
    end
  end
end
