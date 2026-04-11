require "./spec_helper"

require "./concerns/email_template_fields"

Spectator.describe Workaty::EmailTemplateUpdateHandler do
  include EmailTemplateFields

  describe "#patch" do
    context "when the user is authorized" do
      it "updates template just fine (via POST)" do
        user = create_user
        template = create_email_template(adder: user)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("workaty:email:template:update", template_hashed_id: template.hashed_id),
          data: {
            fields: {
              native: {
                "title"   => "New Title",
                "content" => "New Content",
              },
              dynamic: {} of String => String,
            },
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        expect(response.status).to eq(200)

        template.reload
        expect(template.title).to eq("New Title")
        expect(template.content).to eq("New Content")
      end

      context "with dynamic fields" do
        it "updates string fields just fine" do
          user = create_user
          template = create_email_template(adder: user)

          FieldValue.new(
            field: first_name_field,
            resource_id: template.id.as(Int64),
            resource_type: FieldResourceType::EMAIL_TEMPLATE,
            string_value: "Jane"
          ).save!

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:email:template:update", template_hashed_id: template.hashed_id),
            data: {
              fields: {
                native: {
                  "title"   => "Updated Title",
                  "content" => "Updated Content",
                },
                dynamic: {
                  "#{first_name_field.hashed_id}" => "John",
                  "#{city_field.hashed_id}"       => "San Francisco",
                },
              },
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          expect(response.status).to eq(200)

          first_name_value = FieldValue.filter(
            field: first_name_field,
            resource_id: template.id,
            resource_type: FieldResourceType::EMAIL_TEMPLATE
          ).first?
          expect(first_name_value).not_to be_nil
          expect(first_name_value.not_nil!.string_value).to eq("John")

          city_value = FieldValue.filter(
            field: city_field,
            resource_id: template.id,
            resource_type: FieldResourceType::EMAIL_TEMPLATE
          ).first?
          expect(city_value).not_to be_nil
          expect(city_value.not_nil!.string_value).to eq("San Francisco")
        end

        it "can update numeric fields" do
          user = create_user
          template = create_email_template(adder: user)

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:email:template:update", template_hashed_id: template.hashed_id),
            data: {
              fields: {
                native: {
                  "title"   => "Updated Template",
                  "content" => "<p>Updated</p>",
                },
                dynamic: {
                  "#{age_field.hashed_id}"   => "35",
                  "#{score_field.hashed_id}" => "98.5",
                },
              },
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          expect(response.status).to eq(200)

          age_value = FieldValue.filter(
            field: age_field,
            resource_id: template.id,
            resource_type: FieldResourceType::EMAIL_TEMPLATE
          ).first?
          expect(age_value).not_to be_nil
          expect(age_value.not_nil!.integer_value).to eq(35)

          score_value = FieldValue.filter(
            field: score_field,
            resource_id: template.id,
            resource_type: FieldResourceType::EMAIL_TEMPLATE
          ).first?
          expect(score_value).not_to be_nil
          expect(score_value.not_nil!.float_value).to eq(98.5)
        end

        it "can update boolean fields" do
          user = create_user
          template = create_email_template(adder: user)

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:email:template:update", template_hashed_id: template.hashed_id),
            data: {
              fields: {
                native: {
                  "title"   => "Updated Template",
                  "content" => "<p>Updated</p>",
                },
                dynamic: {
                  "#{verified_field.hashed_id}" => "true",
                },
              },
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          expect(response.status).to eq(200)

          verified_value = FieldValue.filter(
            field: verified_field,
            resource_id: template.id,
            resource_type: FieldResourceType::EMAIL_TEMPLATE
          ).first?
          expect(verified_value).not_to be_nil
          expect(verified_value.not_nil!.boolean_value).to be_true
        end
      end

      context "when template belongs to different organization" do
        it "returns 404" do
          user = create_user
          other_user = create_user
          template = create_email_template(adder: other_user)

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:email:template:update", template_hashed_id: template.hashed_id),
            data: {
              fields: {
                native: {
                  "title" => "x", "content" => "x",
                },
                dynamic: {} of String => String,
              },
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json"
          )

          expect(response.status).to eq(404)
        end
      end
    end

    context "when user is not authorized" do
      it "returns 403" do
        user = create_user(role: Auth::Role::SECURITY_STAFF)
        template = create_email_template(adder: create_user(organization: user.organization!))

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("workaty:email:template:update", template_hashed_id: template.hashed_id),
          data: {fields: {native: {"title" => "x", "content" => "x"}, dynamic: {} of String => String}}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        expect(response.status).to eq(403)
      end
    end

    context "when the request has invalid JSON" do
      it "returns 400 with error message" do
        user = create_user
        template = create_email_template(adder: user)

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("workaty:email:template:update", template_hashed_id: template.hashed_id),
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
