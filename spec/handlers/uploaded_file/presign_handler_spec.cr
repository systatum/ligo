require "./spec_helper"

describe UploadedFilePresignHandler do
  after_each do
    PresignedUpload.authorize_hook = ->(account : Ligo::User, declared_size : Int64) { nil.as(Time?) }
    AppSettings.instance.ligo_allow_presigned_upload = true
  end

  it "creates an UploadedFile row and returns a working presigned PUT URL" do
    user = create_user

    response = Marten::Spec.client.post(
      Marten.routes.reverse("uploaded_file_presign"),
      data: {size_bytes: 1_024}.to_json,
      headers: auth_headers_for(user),
      content_type: "application/json"
    )

    response.status.should eq 200
    json = JSON.parse(response.content)
    storage_key = json["storage_key"].as_s

    uploaded = Ligo::UploadedFile.get!(id: storage_key)
    uploaded.byte_size.should eq 1_024
    uploaded.uploaded_by_id.should eq user.id

    upload_url = json["upload_url"].as_s
    put_response = HTTP::Client.put(upload_url, body: "x" * 1_024)
    put_response.status_code.should eq 200
  end

  it "sets expires_at from the authorize_hook's return value" do
    user = create_user
    expiry = Time.local + 1.hour
    PresignedUpload.authorize_hook = ->(account : Ligo::User, declared_size : Int64) { expiry.as(Time?) }

    response = Marten::Spec.client.post(
      Marten.routes.reverse("uploaded_file_presign"),
      data: {size_bytes: 1_024}.to_json,
      headers: auth_headers_for(user),
      content_type: "application/json"
    )

    storage_key = JSON.parse(response.content)["storage_key"].as_s
    uploaded = Ligo::UploadedFile.get!(id: storage_key)
    uploaded.expires_at.should_not be_nil
  end

  it "rejects the upload when the authorize_hook raises" do
    user = create_user
    PresignedUpload.authorize_hook = ->(account : Ligo::User, declared_size : Int64) {
      raise AuthorizationError.new
    }

    response = Marten::Spec.client.post(
      Marten.routes.reverse("uploaded_file_presign"),
      data: {size_bytes: 1_024}.to_json,
      headers: auth_headers_for(user),
      content_type: "application/json"
    )

    response.status.should eq 403
  end

  it "returns 404 when presigned upload is disabled" do
    AppSettings.instance.ligo_allow_presigned_upload = false
    user = create_user

    response = Marten::Spec.client.post(
      Marten.routes.reverse("uploaded_file_presign"),
      data: {size_bytes: 1_024}.to_json,
      headers: auth_headers_for(user),
      content_type: "application/json"
    )

    response.status.should eq 404
  end

  it "returns 403 when unauthenticated" do
    response = Marten::Spec.client.post(
      Marten.routes.reverse("uploaded_file_presign"),
      data: {size_bytes: 1_024}.to_json,
      content_type: "application/json"
    )

    response.status.should eq 403
  end

  it "returns 422 when size_bytes is missing" do
    user = create_user

    response = Marten::Spec.client.post(
      Marten.routes.reverse("uploaded_file_presign"),
      data: {} of String => String,
      headers: auth_headers_for(user),
      content_type: "application/json"
    )

    response.status.should eq 422
  end
end
