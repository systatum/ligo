require "./spec_helper"

describe Ligo::MyPictureUploadHandler do
  context "with valid data" do
    it "uploads profile picture and returns serialized uploaded file" do
      user = create_user
      uploaded = build_http_uploaded_file

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("my_picture_upload"),
        data: profile_picture_param(uploaded),
        headers: auth_headers_for(user),
        content_type: multipart_content_type
      )

      response.status.should eq 200

      user.reload
      user.uploaded_profile_picture_file_id.should_not be_nil

      uploaded_file = Ligo::UploadedFile.get(id: user.uploaded_profile_picture_file_id).not_nil!
      uploaded_file.original_name.should_not be_nil
      uploaded_file.original_name.not_nil!.should_not be_empty
      uploaded_file.content_type.should eq "application/octet-stream"
      uploaded_file.byte_size.should eq PNG_1X1.bytesize.to_i64
      Marten.media_files_storage.exists?(uploaded_file.id.to_s).should be_true

      response.content.should eq UploadedFileSerializer.serialize(uploaded_file)
    end
  end

  context "with invalid data" do
    it "returns 422 when payload is missing profile_picture" do
      user = create_user

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("my_picture_upload"),
        data: {} of String => String,
        headers: auth_headers_for(user)
      )

      response.status.should eq 422
      json = JSON.parse(response.content)
      json["error"]["messages"].as_a.should_not be_empty
    end

    it "returns 422 when uploaded file is not an image" do
      user = create_user
      body = invalid_profile_picture_body(DEFAULT_MULTIPART_BOUNDARY, "not-image.txt", "hello world")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("my_picture_upload"),
        data: body,
        headers: auth_headers_for(user),
        content_type: multipart_content_type
      )

      response.status.should eq 422
      json = JSON.parse(response.content)
      json["error"]["messages"].as_a.should_not be_empty
    end

    it "returns 422 when filename looks like image but payload is not image" do
      user = create_user
      body = invalid_profile_picture_body(
        DEFAULT_MULTIPART_BOUNDARY,
        "looks-like-image.png",
        "this is plain text, not an image"
      )

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("my_picture_upload"),
        data: body,
        headers: auth_headers_for(user),
        content_type: multipart_content_type
      )

      response.status.should eq 422
      json = JSON.parse(response.content)
      json["error"]["messages"].as_a.should_not be_empty
    end
  end

  context "when user is not authenticated" do
    it "returns 403 forbidden" do
      uploaded = build_http_uploaded_file

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("my_picture_upload"),
        data: profile_picture_param(uploaded),
        content_type: multipart_content_type
      )

      response.status.should eq 403
    end
  end

  it "delegates to patch method" do
    user = create_user
    uploaded = build_http_uploaded_file

    response = Marten::Spec.client.post(
      Marten.routes.reverse("my_picture_upload"),
      data: profile_picture_param(uploaded),
      headers: auth_headers_for(user)
    )

    response.status.should eq 200

    user.reload
    user.uploaded_profile_picture_file_id.should_not be_nil

    uploaded_file = Ligo::UploadedFile.get(id: user.uploaded_profile_picture_file_id).not_nil!
    uploaded_file.original_name.should_not be_nil
    uploaded_file.original_name.not_nil!.should_not be_empty
    uploaded_file.content_type.should eq "application/octet-stream"
    uploaded_file.byte_size.should eq PNG_1X1.bytesize.to_i64
    Marten.media_files_storage.exists?(uploaded_file.id.to_s).should be_true

    response.content.should eq UploadedFileSerializer.serialize(uploaded_file)
  end
end
