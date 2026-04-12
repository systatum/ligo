require "./spec_helper"

describe Current do
  it "isolates performer_id across concurrent fibers with middleware" do
    timestamp = Time.utc.to_unix_ms

    users = [] of Auth::User

    100.times do |i|
      users << create_user(email: "fiber-#{i + 1}-#{timestamp}@test.com")
    end

    results = Channel(Tuple(Int64, Int64?)).new(100)

    users.each_with_index do |user, idx|
      spawn do
        response = Marten::Spec.client.post(
          Marten.routes.reverse("api_product_create"),
          data: {name: "FiberProduct#{idx}-#{timestamp}"}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200

        product = Product.filter(name: "FiberProduct#{idx}-#{timestamp}").first
        if product
          changelog = Changelog.filter(
            record_class: "Product",
            record_id: product.id,
            action_type: Changelog::ActionType::CREATE
          ).first

          performer_id = changelog.try(&.performer_id).try(&.to_i64)
          results.send({user.id.not_nil!.to_i64, performer_id})
        end
      end
    end

    collected = [] of Tuple(Int64, Int64?)
    100.times do
      collected << results.receive
    end

    collected.should_not be_empty
    collected.size.should eq 100
    collected.each do |expected_user_id, actual_performer_id|
      actual_performer_id.should_not be_nil
      actual_performer_id.should eq(expected_user_id)
    end
  end
end
