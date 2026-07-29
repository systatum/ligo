require "./spec_helper"

describe Antrikan::OperatingHourCreateHandler do
  context "when the user is authorized" do
    context "with valid data" do
      it "creates a new operating hour for a space" do
        user = create_user
        space = create_space(manager: user)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:operating_hour:create", space_hashed_id: space.hashed_id),
          data: {
            day:        1,
            open_time:  "09:00",
            close_time: "17:00",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        op_hour = Antrikan::OperatingHour.filter(space_id: space.id).last!
        op_hour.space_id.should eq space.id
        op_hour.day!.should eq 1
        op_hour.open_time!.should eq Time::Span.new(hours: 9, minutes: 0)
        op_hour.close_time!.should eq Time::Span.new(hours: 17, minutes: 0)

        response.content.should eq Antrikan::OperatingHourSerializer.serialize(op_hour)
      end

      context "when the space does not exist" do
        it "raises an error" do
          user = create_user
          fake_hashed_id = IdConcealer.encode(999999999)

          response = Marten::Spec.client.post(
            Marten.routes.reverse("antrikan:space:operating_hour:create", space_hashed_id: fake_hashed_id),
            data: {
              day:        1,
              open_time:  "09:00",
              close_time: "17:00",
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          response.status.should eq 404
        end
      end
    end

    context "with invalid data" do
      it "raises an error when day is missing" do
        user = create_user
        space = create_space(manager: user)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:operating_hour:create", space_hashed_id: space.hashed_id),
          data: {
            open_time:  "09:00",
            close_time: "17:00",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
      end
    end
  end

  context "when the user is not authorized" do
    it "returns 400" do
      user = create_user
      space = create_space(manager: user)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:operating_hour:create", space_hashed_id: space.hashed_id),
        data: {
          day:        1,
          open_time:  "09:00",
          close_time: "17:00",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end
  end

  context "nested under a channel" do
    it "creates a new operating hour for the channel" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:operating_hour:create", channel_hashed_id: channel.hashed_id),
        data: {
          day:        1,
          open_time:  "09:00",
          close_time: "17:00",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      op_hour = Antrikan::OperatingHour.filter(channel_id: channel.id).last!
      op_hour.channel_id.should eq channel.id
      op_hour.day!.should eq 1

      response.content.should eq Antrikan::OperatingHourSerializer.serialize(op_hour)
    end

    it "returns 400 when the user is not authorized" do
      space = create_space
      channel = create_channel(space: space)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:channel:operating_hour:create", channel_hashed_id: channel.hashed_id),
        data: {
          day:        1,
          open_time:  "09:00",
          close_time: "17:00",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end
  end

  context "nested under an item" do
    it "creates a new operating hour for the item" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:item:operating_hour:create", item_slug: item.slug!),
        data: {
          day:        1,
          open_time:  "14:00",
          close_time: "16:00",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 201

      op_hour = Antrikan::OperatingHour.filter(item_id: item.id).last!
      op_hour.item_id.should eq item.id
      op_hour.day!.should eq 1

      response.content.should eq Antrikan::OperatingHourSerializer.serialize(op_hour)
    end

    it "returns 400 when the user is not authorized" do
      item = create_item

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:item:operating_hour:create", item_slug: item.slug!),
        data: {
          day:        1,
          open_time:  "14:00",
          close_time: "16:00",
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end
  end
end
