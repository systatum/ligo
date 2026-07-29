require "./spec_helper"

describe Antrikan::VoucherCreateHandler do
  context "when the user is the space owner" do
    it "creates a voucher with an auto-generated code" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:voucher:create", space_hashed_id: space.hashed_id),
        data: {space_percentage_discount: 10.0}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      voucher = Antrikan::Voucher.last!
      voucher.space_id.should eq space.id
      voucher.code.should_not be_nil
      voucher.space_percentage_discount.should eq 10.0

      response.content.should eq Antrikan::VoucherSerializer.serialize(voucher)
    end

    it "creates a voucher with discountable_items covering every mode" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:voucher:create", space_hashed_id: space.hashed_id),
        data: {
          code:               "SAVE10",
          channel_id:         channel.hashed_id,
          discountable_items: [
            {item_id: item.slug, percentage_discount: 15.0, mode: "override"},
          ],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      voucher = Antrikan::Voucher.last!
      entries = voucher.discountable_items.not_nil!.entries
      entries.size.should eq 1
      entries[0].item_id.should eq item.slug
      entries[0].mode.should eq "override"
    end

    it "creates a bounded voucher with starts_at/expires_at" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:voucher:create", space_hashed_id: space.hashed_id),
        data: {
          indeterminate: false,
          starts_at:     "2026-01-01T00:00:00Z",
          expires_at:    "2026-12-31T23:59:59Z",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      voucher = Antrikan::Voucher.last!
      voucher.indeterminate.should be_false
      voucher.starts_at.should_not be_nil
      voucher.expires_at.should_not be_nil
    end

    it "rejects indeterminate: false without starts_at/expires_at" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:voucher:create", space_hashed_id: space.hashed_id),
        data: {
          indeterminate: false,
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "rejects an invalid mode" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:voucher:create", space_hashed_id: space.hashed_id),
        data: {
          discountable_items: [
            {item_id: item.slug, percentage_discount: 15.0, mode: "not_a_real_mode"},
          ],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the user is not the space owner" do
    it "returns 403" do
      user = create_user
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:voucher:create", space_hashed_id: space.hashed_id),
        data: {} of String => String,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end
end
