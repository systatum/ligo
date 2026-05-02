require "./spec_helper"

describe Antrikan::ItemUpdateHandler do
  context "when the user is an admin" do
    it "updates the name" do
      user = create_user
      item = create_item(name: "Old Name")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {name: "New Name"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.name.should eq "New Name"

      response.content.should eq Antrikan::ItemSerializer.serialize(item)
    end

    it "updates the order" do
      user = create_user
      item = create_item(order: 0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {order: 3}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.order.should eq 3
    end

    it "updates the daily_cap" do
      user = create_user
      item = create_item(daily_cap: 0)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {daily_cap: 10}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.daily_cap.should eq 10
    end

    it "accepts a negative daily_cap to indicate no cap" do
      user = create_user
      item = create_item(daily_cap: 5)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {daily_cap: -1}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.daily_cap.should eq -1
    end

    it "updates is_monitored" do
      user = create_user
      item = create_item(is_monitored: false)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {is_monitored: true}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.is_monitored.should eq true
    end

    it "updates the description" do
      user = create_user
      item = create_item(description: nil)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {description: "A new description"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.description.should eq "A new description"
    end

    it "clears the description when sent as null" do
      user = create_user
      item = create_item(description: "Some description")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {description: nil}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.description.should be_nil
    end

    it "uploads a main_image when provided" do
      user = create_user
      item = create_item

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {
          main_image: {
            base64_bytes: Base64.encode(PNG_1X1),
            mimetype:     "image/png",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.main_image_file_id.should_not be_nil
    end

    it "clears the main_image when sent as null" do
      user = create_user
      file = create_uploaded_file_metadata
      item = create_item(main_image_file_id: file.id)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {main_image: nil}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.main_image_file_id.should be_nil
    end

    it "does not change fields that are not in the request body" do
      user = create_user
      item = create_item(name: "Original", description: "Original desc", order: 1)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {name: "Updated"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.name.should eq "Updated"
      item.description.should eq "Original desc"
      item.order.should eq 1
    end
  end

  context "when the request has invalid payload" do
    it "returns 422 for a name that is too long" do
      user = create_user
      item = create_item

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {name: "a" * 256}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 422 when main_image is not an image" do
      user = create_user
      item = create_item

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {
          main_image: {
            base64_bytes: Base64.encode("not an image"),
            mimetype:     "text/plain",
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the user is not an admin" do
    it "returns 403 and does not update the item" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      item = create_item(name: "Original")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {name: "Hacked"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 403

      item.reload
      item.name.should eq "Original"
    end
  end

  context "when the user is not authenticated" do
    it "returns 400 and does not update the item" do
      item = create_item(name: "Original")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {name: "Hacked"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400

      item.reload
      item.name.should eq "Original"
    end
  end
end
