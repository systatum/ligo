require "./spec_helper"

require "./concerns/email_template_fields"

Spectator.describe Workaty::EmailTemplateCreateHandler do
  include EmailTemplateFields

  describe "#post" do
    context "when the user is authorized" do
      it "creates a new email template" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("workaty:email:template:create"),
          data: {
            fields: {
              native: {
                "title"   => "Welcome Email",
                "content" => "<p>Welcome to our platform!</p>",
              },
              dynamic: {} of String => String,
            },
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        expect(response.status).to eq(200)

        template = Workaty::EmailTemplate.last!
        expect(template.organization).to eq(user.organization)
        expect(template.title).to eq("Welcome Email")
        expect(template.content).to eq("<p>Welcome to our platform!</p>")

        json_response = JSON.parse(response.content)
        expect(json_response["records"]).not_to be_nil
        expect(json_response["fields"]).not_to be_nil
      end

      context "with dynamic fields" do
        it "creates a new email template with multiple data types" do
          user = create_user

          response = Marten::Spec.client.post(
            Marten.routes.reverse("workaty:email:template:create"),
            data: {
              fields: {
                native: {
                  "title"   => "Email Template",
                  "content" => "<p>Email details</p>",
                },
                dynamic: {
                  "#{category_field.hashed_id}"    => "Hiring",
                  "#{is_reviewed_field.hashed_id}" => "true",
                },
              },
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          expect(response.status).to eq(200)

          template = Workaty::EmailTemplate.last!

          category_value = FieldValue.filter(
            field: category_field,
            resource_id: template.id,
            resource_type: FieldResourceType::EMAIL_TEMPLATE
          ).first?
          expect(category_value).not_to be_nil
          expect(category_value.not_nil!.string_value).to eq("Hiring")

          is_reviewed_value = FieldValue.filter(
            field: is_reviewed_field,
            resource_id: template.id,
            resource_type: FieldResourceType::EMAIL_TEMPLATE
          ).first?
          expect(is_reviewed_value).not_to be_nil
          expect(is_reviewed_value.not_nil!.boolean_value).to be_true
        end
      end
    end

    context "when the user is not authorized" do
      it "returns 403" do
        user = create_user(role: Auth::Role::SECURITY_STAFF)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("workaty:email:template:create"),
          data: {fields: {dynamic: {} of String => String}}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        expect(response.status).to eq(403)
      end
    end

    context "when the request has invalid JSON" do
      it "returns 400 with error message" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("workaty:email:template:create"),
          data: "{\"fields\": {\"native\": {\"title\": \"Test\",}}}",
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        expect(response.status).to eq(400)

        json_response = JSON.parse(response.content)
        expect(json_response["error"]["messages"].as_a).to eq(["Invalid JSON format"])
      end
    end
  end
end
