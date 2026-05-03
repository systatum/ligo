require "./spec_helper"

require "./concerns/email_template_fields"

Spectator.describe Workaty::EmailTemplateShowHandler do
  include EmailTemplateFields

  context "when the user is authorized" do
    it "returns the template with fields" do
      user = create_user
      template = create_email_template(adder: user)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:email:template:show", template_hashed_id: template.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      expect(response.status).to eq(200)

      json_response = JSON.parse(response.content)
      expect(json_response["records"]).not_to be_nil
      expect(json_response["fields"]).not_to be_nil

      records = json_response["records"].as_h
      expect(records["EMAIL_TEMPLATE"].as_a.size).to eq(1)
    end

    it "returns template with dynamic field values" do
      user = create_user
      template = create_email_template(adder: user, title: "Customer Email", content: "<p>Hello {{name}}</p>")

      FieldValue.new(
        field: customer_name_field,
        resource_id: template.id.as(Int64),
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        string_value: "Alice Smith"
      ).save!

      FieldValue.new(
        field: birth_place_field,
        resource_id: template.id.as(Int64),
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        string_value: "Boston"
      ).save!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:email:template:show", template_hashed_id: template.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      expect(response.status).to eq(200)

      json_response = JSON.parse(response.content)
      records = json_response["records"].as_h["EMAIL_TEMPLATE"].as_a
      expect(records.size).to eq(1)

      record = records.first.as_h
      expect(record["title"].as_s).to eq("Customer Email")
      expect(record["content"].as_s).to eq("<p>Hello {{name}}</p>")

      expect(record["customer_name"].as_s).to eq("Alice Smith")
      expect(record["birth_place"].as_s).to eq("Boston")
    end

    it "returns template with multiple data type dynamic fields" do
      user = create_user
      template = create_email_template(adder: user)

      FieldValue.new(
        field: birth_place_field,
        resource_id: template.id.as(Int64),
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        string_value: "Boston"
      ).save!

      FieldValue.new(
        field: rating_field,
        resource_id: template.id.as(Int64),
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        float_value: 4.8
      ).save!

      FieldValue.new(
        field: active_field,
        resource_id: template.id.as(Int64),
        resource_type: FieldResourceType::EMAIL_TEMPLATE,
        boolean_value: true
      ).save!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:email:template:show", template_hashed_id: template.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      expect(response.status).to eq(200)

      json_response = JSON.parse(response.content)
      records = json_response["records"].as_h["EMAIL_TEMPLATE"].as_a
      record = records.first.as_h

      expect(record["birth_place"].as_s).to eq("Boston")
      expect(record["rating"].as_f).to eq(4.8)
      expect(record["is_active"].as_bool).to be_true
    end
  end

  context "when template belongs to different organization" do
    it "returns 404" do
      user = create_user
      other_user = create_user
      template = create_email_template(adder: other_user)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:email:template:show", template_hashed_id: template.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      expect(response.status).to eq(404)
    end
  end

  context "when user is not authorized" do
    it "returns 403" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      template = create_email_template(adder: create_user(organization: user.organization!))

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:email:template:show", template_hashed_id: template.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      expect(response.status).to eq(403)
    end
  end
end
