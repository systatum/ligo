require "./spec_helper"

describe Antrikan::VoucherShowHandler do
  context "when the user owns the voucher's space" do
    it "returns the voucher" do
      user = create_user
      space = create_space(manager: user)
      voucher = create_voucher(space: space)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:voucher:show", voucher_hashed_id: voucher.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should eq Antrikan::VoucherSerializer.serialize(voucher)
    end
  end

  context "when the user does not own the voucher's space" do
    it "returns 403" do
      voucher = create_voucher
      other_user = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:voucher:show", voucher_hashed_id: voucher.hashed_id),
        headers: {authorization: "Bearer #{other_user.jwt_token}"}
      )

      response.status.should eq 403
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      voucher = create_voucher

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:voucher:show", voucher_hashed_id: voucher.hashed_id)
      )

      response.status.should eq 400
    end
  end
end
