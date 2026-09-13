require "../../spec_helper"

describe Ligo::BioUpdateHandler do
  context "with valid data" do
    it "updates all user bio fields" do
      user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {
              first_name:              "Jane",
              last_name:               "Smith",
              locale:                  "id-ID",
              timezone_offset_seconds: 3600,
            },
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      user.reload
      user.first_name.should eq "Jane"
      user.last_name.should eq "Smith"
      user.locale.should eq "id-ID"
      user.timezone_offset_seconds.should eq 3600

      response.content.should eq UserSerializer.serialize(user)
    end

    it "updates only first_name when provided" do
      user = create_user
      original_locale = user.locale

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {
              first_name: "Jane",
            },
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      user.reload
      user.first_name.should eq "Jane"
      user.last_name.should eq "User"
      user.locale.should eq original_locale
    end

    it "updates only last_name when provided" do
      user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {
              last_name: "Williams",
            },
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      user.reload
      user.first_name.should eq "Test"
      user.last_name.should eq "Williams"
    end

    it "updates only locale when provided" do
      user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {
              locale: "ja-JP",
            },
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      user.reload
      user.locale.should eq "ja-JP"
    end

    it "updates only timezone_offset_seconds when provided" do
      user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {
              timezone_offset_seconds: -18000,
            },
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      user.reload
      user.timezone_offset_seconds.should eq -18000
    end

    it "accepts empty fields object" do
      user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {} of String => String,
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      user.reload
      user.first_name.should eq "Test"
      user.last_name.should eq "User"
    end
  end

  context "with invalid data" do
    it "rejects invalid locale" do
      user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {
              locale: "fr-FR",
            },
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422

      json_response = JSON.parse(response.content)
      json_response["error"]["messages"].as_a.should contain("Locale: Must be one of: en-US, id-ID, ja-JP")
    end

    it "rejects locale that is not a valid format" do
      user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {
              locale: "invalid-locale-format",
            },
          },
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when user is not authenticated" do
    it "returns 403 forbidden" do
      response = Marten::Spec.client.patch(
        Marten.routes.reverse("bio_update"),
        data: {
          fields: {
            native: {
              first_name: "Jane",
            },
          },
        }.to_json,
        content_type: "application/json"
      )

      response.status.should eq 403
    end
  end

  it "delegates to patch method" do
    user = create_user

    response = Marten::Spec.client.post(
      Marten.routes.reverse("bio_update"),
      data: {
        fields: {
          native: {
            first_name: "Jane",
          },
        },
      }.to_json,
      headers: {authorization: "Bearer #{user.jwt_token}"},
      content_type: "application/json"
    )

    response.status.should eq 200

    user.reload
    user.first_name.should eq "Jane"
  end
end
