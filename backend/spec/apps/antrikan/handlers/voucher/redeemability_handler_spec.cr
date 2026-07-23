require "./spec_helper"

describe Antrikan::VoucherRedeemabilityHandler do
  it "returns redeemable: true for a usable voucher" do
    channel = create_channel
    queuer = create_queuer(space: channel.space.not_nil!)
    queue = create_queue(channel: channel, queuer: queuer)
    voucher = create_voucher(space: channel.space.not_nil!, code: "SAVE10", space_percentage_discount: 10.0)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:voucher:redeemable"),
      query_params: {queue_id: queue.slug!, code: voucher.code.not_nil!}
    )

    response.status.should eq 200
    json = JSON.parse(response.content)
    json["redeemable"].as_bool.should be_true
    json["error_code"].raw.should be_nil
  end

  it "returns redeemable: false with ERR_VOUCH_NOT_FOUND for an unknown code" do
    channel = create_channel
    queuer = create_queuer(space: channel.space.not_nil!)
    queue = create_queue(channel: channel, queuer: queuer)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:voucher:redeemable"),
      query_params: {queue_id: queue.slug!, code: "NOT-A-CODE"}
    )

    response.status.should eq 200
    json = JSON.parse(response.content)
    json["redeemable"].as_bool.should be_false
    json["error_code"].as_s.should eq Antrikan::ErrorCode::VOUCHER_NOT_FOUND
  end

  it "returns redeemable: false with ERR_VOUCH_INACTIVE for a voucher outside its active window" do
    channel = create_channel
    queuer = create_queuer(space: channel.space.not_nil!)
    queue = create_queue(channel: channel, queuer: queuer)
    voucher = create_voucher(
      space: channel.space.not_nil!,
      code: "EXPIRED",
      space_percentage_discount: 10.0,
      indeterminate: false,
      starts_at: Time.utc(2020, 1, 1),
      expires_at: Time.utc(2020, 12, 31)
    )

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:voucher:redeemable"),
      query_params: {queue_id: queue.slug!, code: voucher.code.not_nil!}
    )

    response.status.should eq 200
    json = JSON.parse(response.content)
    json["redeemable"].as_bool.should be_false
    json["error_code"].as_s.should eq Antrikan::ErrorCode::VOUCHER_INACTIVE
  end

  it "returns redeemable: false with ERR_VOUCH_NOANON when the queuer has no registered user" do
    channel = create_channel
    queuer = create_queuer(space: channel.space.not_nil!)
    queue = create_queue(channel: channel, queuer: queuer)
    voucher = create_voucher(
      space: channel.space.not_nil!,
      code: "MEMBERS10",
      space_percentage_discount: 10.0,
      anon_redeemable: false
    )

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:voucher:redeemable"),
      query_params: {queue_id: queue.slug!, code: voucher.code.not_nil!}
    )

    response.status.should eq 200
    json = JSON.parse(response.content)
    json["redeemable"].as_bool.should be_false
    json["error_code"].as_s.should eq Antrikan::ErrorCode::VOUCHER_NOT_ANON_REDEEMABLE
  end

  it "does not create an AppliedVoucher as a side effect" do
    channel = create_channel
    queuer = create_queuer(space: channel.space.not_nil!)
    queue = create_queue(channel: channel, queuer: queuer)
    voucher = create_voucher(space: channel.space.not_nil!, code: "SAVE10", space_percentage_discount: 10.0)

    Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:voucher:redeemable"),
      query_params: {queue_id: queue.slug!, code: voucher.code.not_nil!}
    )

    Antrikan::AppliedVoucher.filter(queue_id: queue.id!).exists?.should be_false
  end

  it "returns 422 when the code query parameter is missing" do
    channel = create_channel
    queuer = create_queuer(space: channel.space.not_nil!)
    queue = create_queue(channel: channel, queuer: queuer)

    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:voucher:redeemable"),
      query_params: {queue_id: queue.slug!}
    )

    response.status.should eq 422
  end

  it "returns 422 when the queue_id query parameter is missing" do
    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:voucher:redeemable"),
      query_params: {code: "SAVE10"}
    )

    response.status.should eq 422
  end

  it "returns 404 when queue_id does not match any queue" do
    response = Marten::Spec.client.get(
      Marten.routes.reverse("antrikan:voucher:redeemable"),
      query_params: {queue_id: "UNKNOWN00", code: "SAVE10"}
    )

    response.status.should eq 404
  end
end
