require "./spec_helper"

describe Antrikan::OperatingHourUpdateHandler do
  context "when the operating hour cannot be found" do
    it "renders 404" do
      user = create_user
      space = create_space(manager: user)
      fake_hashed_id = IdConcealer.encode(999999999)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:operating_hour:update",
          space_hashed_id: space.hashed_id,
          operating_hour_hashed_id: fake_hashed_id
        ),
        data: {
          day:        1,
          open_time:  "08:00",
          close_time: "18:00",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 404
      response.content.should eq({error: {messages: ["Not found"]}}.to_json)
    end
  end

  context "when the operating hour can be found" do
    context "when the user is authorized" do
      it "will be updated" do
        user = create_user
        space = create_space(manager: user)
        op_hour = create_operating_hour(
          space: space,
          day: 1,
          open_time: Time::Span.new(hours: 9, minutes: 0),
          close_time: Time::Span.new(hours: 17, minutes: 0)
        )

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:space:operating_hour:update",
            space_hashed_id: space.hashed_id,
            operating_hour_hashed_id: op_hour.hashed_id
          ),
          data: {
            day:        1,
            open_time:  "08:00",
            close_time: "18:00",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200

        op_hour.reload
        op_hour.day!.should eq 1
        op_hour.open_time!.should eq Time::Span.new(hours: 8, minutes: 0)
        op_hour.close_time!.should eq Time::Span.new(hours: 18, minutes: 0)

        response.content.should eq Antrikan::OperatingHourSerializer.serialize(op_hour)
      end
    end

    context "when the operating hour belongs to another space" do
      it "will not be updated" do
        user = create_user
        space1 = create_space(manager: user)
        space2 = create_space(manager: user)
        op_hour = create_operating_hour(space: space2, day: 1)

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("antrikan:space:operating_hour:update",
            space_hashed_id: space1.hashed_id,
            operating_hour_hashed_id: op_hour.hashed_id
          ),
          data: {
            day:        1,
            open_time:  "08:00",
            close_time: "18:00",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 404
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)

        op_hour.reload
        op_hour.open_time.should_not eq Time::Span.new(hours: 8, minutes: 0)
        op_hour.close_time.should_not eq Time::Span.new(hours: 18, minutes: 0)
      end
    end
  end

  context "when the user is not authorized" do
    it "returns 400" do
      user = create_user
      space = create_space(manager: user)
      op_hour = create_operating_hour(space: space, day: 1)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:operating_hour:update",
          space_hashed_id: space.hashed_id,
          operating_hour_hashed_id: op_hour.hashed_id
        ),
        data: {
          day:        1,
          open_time:  "08:00",
          close_time: "18:00",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
      op_hour.reload
      op_hour.open_time.should_not eq Time::Span.new(hours: 8, minutes: 0)
      op_hour.close_time.should_not eq Time::Span.new(hours: 18, minutes: 0)
    end
  end

  context "nested under a channel" do
    it "updates an operating hour belonging to the channel" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      op_hour = create_operating_hour(channel: channel, day: 1)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:channel:operating_hour:update",
          channel_hashed_id: channel.hashed_id,
          operating_hour_hashed_id: op_hour.hashed_id
        ),
        data: {
          day:        1,
          open_time:  "08:00",
          close_time: "18:00",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      op_hour.reload
      op_hour.open_time!.should eq Time::Span.new(hours: 8, minutes: 0)
    end
  end

  context "nested under an item" do
    it "updates an operating hour belonging to the item" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      op_hour = create_operating_hour(item: item, day: 1)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:operating_hour:update",
          item_slug: item.slug!,
          operating_hour_hashed_id: op_hour.hashed_id
        ),
        data: {
          day:        1,
          open_time:  "14:00",
          close_time: "16:00",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      op_hour.reload
      op_hour.open_time!.should eq Time::Span.new(hours: 14, minutes: 0)
    end
  end
end
