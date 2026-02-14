require "./spec_helper"

require "./concerns/email_template_fields"

Spectator.describe Workaty::EmailTemplateIndexHandler do
  include EmailTemplateFields

  describe "#get" do
    context "when the user is authorized" do
      it "returns all templates for the organization" do
        user = create_user
        template1 = create_email_template(adder: user)
        template2 = create_email_template(adder: user)

        other_user = create_user
        template3 = create_email_template(adder: other_user)

        response = Marten::Spec.client.get(
          Marten.routes.reverse("workaty:email:template:index"),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        expect(response.status).to eq(200)

        json_response = JSON.parse(response.content)
        records = json_response["records"].as_h["EMAIL_TEMPLATE"].as_a

        expect(records.size).to eq(2)

        ids = records.map { |r| r.as_h["id"].as_s }
        expect(ids).to contain(template1.hashed_id)
        expect(ids).to contain(template2.hashed_id)
        expect(ids).not_to contain(template3.hashed_id)
      end

      it "returns fields definition" do
        user = create_user

        # Trigger field creation via let blocks
        title_field
        content_field

        response = Marten::Spec.client.get(
          Marten.routes.reverse("workaty:email:template:index"),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        expect(response.status).to eq(200)

        json_response = JSON.parse(response.content)
        fields = json_response["fields"].as_h["EMAIL_TEMPLATE"].as_a

        expect(fields.size).to eq(2)

        expect(fields[0]["id"].as_s).to eq(title_field.hashed_id)
        expect(fields[0]["native"].as_bool).to eq(true)
        expect(fields[0]["type"].as_s).to eq("DTYPE_STRING")
        expect(fields[0]["caption"].as_h["en"].as_s).to eq("Title")

        expect(fields[1]["id"].as_s).to eq(content_field.hashed_id)
        expect(fields[1]["native"].as_bool).to eq(true)
        expect(fields[1]["type"].as_s).to eq("DTYPE_TEXT_RICH")
        expect(fields[1]["caption"].as_h["en"].as_s).to eq("Content")
      end

      it "returns templates with dynamic field values" do
        user = create_user

        template1 = create_email_template(adder: user, title: "Template 1")
        FieldValue.new(
          field: first_name_field,
          resource_id: template1.id.as(Int64),
          resource_type: FieldResourceType::EMAIL_TEMPLATE,
          string_value: "John"
        ).save!
        FieldValue.new(
          field: birth_place_field,
          resource_id: template1.id.as(Int64),
          resource_type: FieldResourceType::EMAIL_TEMPLATE,
          string_value: "New York"
        ).save!

        template2 = create_email_template(adder: user, title: "Template 2")
        FieldValue.new(
          field: first_name_field,
          resource_id: template2.id.as(Int64),
          resource_type: FieldResourceType::EMAIL_TEMPLATE,
          string_value: "Jane"
        ).save!
        FieldValue.new(
          field: birth_place_field,
          resource_id: template2.id.as(Int64),
          resource_type: FieldResourceType::EMAIL_TEMPLATE,
          string_value: "Boston"
        ).save!

        response = Marten::Spec.client.get(
          Marten.routes.reverse("workaty:email:template:index"),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        expect(response.status).to eq(200)

        json_response = JSON.parse(response.content)
        records = json_response["records"].as_h["EMAIL_TEMPLATE"].as_a
        expect(records.size).to eq(2)

        expect(records[0]["title"].as_s).to eq("Template 1")
        expect(records[0]["first_name"].as_s).to eq("John")
        expect(records[0]["birth_place"].as_s).to eq("New York")

        expect(records[1]["title"].as_s).to eq("Template 2")
        expect(records[1]["first_name"].as_s).to eq("Jane")
        expect(records[1]["birth_place"].as_s).to eq("Boston")
      end
    end

    context "when user is not authorized" do
      it "returns 403" do
        user = create_user(role: Auth::Role::SECURITY_STAFF)

        response = Marten::Spec.client.get(
          Marten.routes.reverse("workaty:email:template:index"),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        expect(response.status).to eq(403)
      end
    end
  end
end
