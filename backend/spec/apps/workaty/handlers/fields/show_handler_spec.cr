require "../../spec_helper"

describe Workaty::FieldsShowHandler do
  before_each do
    FieldDefinition.all.delete
  end

  describe "#get" do
    it "returns field definitions for a given resource type" do
      title_field = FieldDefinition.new(
        name: "title",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: true,
        localized_name: LocalizedName.new(english: "Title", indonesian: "Judul")
      )
      title_field.save!

      content_field = FieldDefinition.new(
        name: "content",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_TEXT_RICH,
        is_system_field: true,
        localized_name: LocalizedName.new(english: "Content")
      )
      content_field.save!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:fields:show", resource_type: 3)
      )

      response.status.should eq 200
      response.headers["Cache-Control"]?.should eq "public, max-age=3600"

      json_response = JSON.parse(response.content)
      fields = json_response["fields"]

      fields.size.should eq 2

      # check the first field manually
      fields[0]["id"].as_s.should eq title_field.hashed_id
      fields[0]["native"].as_bool.should eq true
      fields[0]["type"].as_s.should eq "DTYPE_STRING"
      fields[0]["caption"].as_h["en"].as_s.should eq "Title"

      # check the second field manually
      fields[1]["id"].as_s.should eq content_field.hashed_id
      fields[1]["type"].as_s.should eq "DTYPE_TEXT_RICH"
    end

    it "returns 404 for invalid resource type" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:fields:show", resource_type: 999)
      )

      response.status.should eq 404
    end

    it "returns empty array when no fields exist" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:fields:show", resource_type: 3)
      )

      response.status.should eq 200

      json_response = JSON.parse(response.content)
      fields = json_response["fields"].as_a
      fields.size.should eq 0
    end

    it "only returns fields for the specified resource type" do
      email_field = FieldDefinition.new(
        name: "title",
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        data_type: FieldDataType::DTYPE_STRING
      )
      email_field.save!

      candidate_field = FieldDefinition.new(
        name: "first_name",
        resource_type: FieldResourceType::CANDIDATE,
        data_type: FieldDataType::DTYPE_STRING
      )
      candidate_field.save!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:fields:show", resource_type: 3)
      )

      response.status.should eq 200

      json_response = JSON.parse(response.content)
      fields = json_response["fields"]

      fields.size.should eq 1

      fields[0]["id"].as_s.should eq email_field.hashed_id
    end
  end
end
