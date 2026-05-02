require "./spec_helper"

describe Antrikan::ItemShowHandler do
  context "with valid request" do
    it "returns the item" do
      item = create_item(name: "8AM", description: "Morning slot")

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:item:show", slug: item.slug!)
      )

      response.status.should eq 200
      response.content.should eq Antrikan::ItemSerializer.serialize(item)
    end

    it "returns the item with a main image URL" do
      file = create_uploaded_file_metadata
      item = create_item(main_image_file_id: file.id)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:item:show", slug: item.slug!)
      )

      response.status.should eq 200

      json_response = JSON.parse(response.content)
      json_response["main_image"].should_not eq nil
    end
  end

  context "when the request has invalid or unexpected payload" do
    it "returns 404 if the item is deleted" do
      item = create_item
      item.soft_delete!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:item:show", slug: item.slug!)
      )

      response.status.should eq 404
    end

    it "returns 404 if the item's channel is deleted" do
      channel = create_channel
      item = create_item(channel: channel)
      channel.soft_delete!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:item:show", slug: item.slug!)
      )

      response.status.should eq 404
    end

    it "return 404 if the slug is non-existent" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:item:show", slug: "ZZZZZZ")
      )

      response.status.should eq 404
    end
  end
end
