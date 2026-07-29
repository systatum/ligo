require "./spec_helper"

describe Antrikan::VoucherUpdateHandler do
  context "when the user owns the voucher's space" do
    it "updates the voucher" do
      user = create_user
      space = create_space(manager: user)
      voucher = create_voucher(space: space, name: "Old Name", space_percentage_discount: 10.0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:voucher:update", voucher_hashed_id: voucher.hashed_id),
        data: {name: "New Name", space_percentage_discount: 20.0}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      voucher.reload
      voucher.name.should eq "New Name"
      voucher.space_percentage_discount.should eq 20.0

      response.content.should eq Antrikan::VoucherSerializer.serialize(voucher)
    end

    it "returns 422 with an invalid discountable_items mode" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      voucher = create_voucher(space: space)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:voucher:update", voucher_hashed_id: voucher.hashed_id),
        data: {
          discountable_items: [
            {item_id: item.slug, percentage_discount: 15.0, mode: "not_a_mode"},
          ],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the user does not own the voucher's space" do
    it "returns 403" do
      voucher = create_voucher
      other_user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:voucher:update", voucher_hashed_id: voucher.hashed_id),
        data: {name: "New Name"}.to_json,
        headers: {authorization: "Bearer #{other_user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      voucher = create_voucher

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:voucher:update", voucher_hashed_id: voucher.hashed_id),
        data: {name: "New Name"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end
  end
end
