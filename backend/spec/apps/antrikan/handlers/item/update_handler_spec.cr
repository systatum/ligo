require "./spec_helper"

describe Antrikan::ItemUpdateHandler do
  context "when the user owns the item's space" do
    it "updates the name" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, name: "Old Name")

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, order: 0)

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, daily_cap: 0)

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, daily_cap: 5)

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

    it "updates the unit_price and unit_currency" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, unit_price: 0_i64, unit_currency: Antrikan::Currency::IDR.value)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {unit_price: 15000, unit_currency: "USD"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.unit_price.should eq 15000
      item.unit_currency.should eq Antrikan::Currency::USD.value

      response.content.should eq Antrikan::ItemSerializer.serialize(item)
    end

    it "returns 422 when unit_currency is not a known currency" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, unit_currency: Antrikan::Currency::IDR.value)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {unit_currency: "GBP"}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      item.reload
      item.unit_currency.should eq Antrikan::Currency::IDR.value
    end

    it "updates is_monitored" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, is_monitored: false)

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, description: nil)

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, description: "Some description")

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      file = create_uploaded_file_metadata
      item = create_item(channel: channel, main_image_file_id: file.id)

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

    it "reorders carousel images using keep_id only, without re-uploading" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      first = create_uploaded_file_metadata
      second = create_uploaded_file_metadata
      item.carousel_image_ids = UploadedFileIds.new(ids: [first.id.to_s, second.id.to_s])
      item.save!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {
          carousel_images: [{keep_id: second.id.to_s}, {keep_id: first.id.to_s}],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.carousel_image_ids!.ids.should eq [second.id.to_s, first.id.to_s]
    end

    it "mixes a kept carousel image with a freshly uploaded one" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      existing = create_uploaded_file_metadata
      item.carousel_image_ids = UploadedFileIds.new(ids: [existing.id.to_s])
      item.save!

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {
          carousel_images: [
            {keep_id: existing.id.to_s},
            {base64_bytes: Base64.encode(PNG_1X1), mimetype: "image/png"},
          ],
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.carousel_image_ids!.ids.size.should eq 2
      item.carousel_image_ids!.ids[0].should eq existing.id.to_s
      item.carousel_image_ids!.ids[1].should_not eq existing.id.to_s
    end

    it "returns 422 when a carousel keep_id does not reference an existing image on this item" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)
      unrelated = create_uploaded_file_metadata

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {carousel_images: [{keep_id: unrelated.id.to_s}]}.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      item.reload
      item.carousel_image_ids.should be_nil
    end

    it "does not change fields that are not in the request body" do
      user = create_user
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel, name: "Original", description: "Original desc", order: 1)

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)

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
      space = create_space(manager: user)
      channel = create_channel(space: space)
      item = create_item(channel: channel)

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

  context "when the user has an insufficient role and does not own the space" do
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

  context "when the user owns an unrelated space" do
    it "returns 403 and does not update the item" do
      user = create_user
      create_space(manager: user)
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

  context "when the user has OWNER role in the same organization as the space owner" do
    it "updates the item" do
      organization = create_organization
      space_owner = create_user(organization: organization)
      space = create_space(manager: space_owner)
      channel = create_channel(space: space)
      item = create_item(channel: channel, name: "Original")
      colleague = create_user(organization: organization, role: Auth::Role::OWNER)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:item:update", slug: item.slug!),
        data: {name: "Updated by colleague"}.to_json,
        headers: {authorization: "Bearer #{colleague.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      item.reload
      item.name.should eq "Updated by colleague"
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
