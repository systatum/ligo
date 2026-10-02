require "./spec_helper"

describe UploadedFileDownloadUrlHandler do
  after_each do
    AppSettings.instance.ligo_allow_presigned_upload = true
  end

  it "returns a presigned GET URL that serves what was uploaded" do
    user = create_user
    uploaded = Ligo::UploadedFile.create_opaque!(byte_size: 5_i64, uploaded_by: user)
    bucket = AppSettings.instance.ligo_uploaded_file_bucket
    put_url = S3PresignerService.presigned_put_url(bucket, uploaded.id.to_s)
    HTTP::Client.put(put_url, body: "hello").status_code.should eq 200

    response = Marten::Spec.client.get(
      Marten.routes.reverse("uploaded_file_download_url", id: uploaded.id),
      headers: auth_headers_for(user)
    )

    response.status.should eq 200
    download_url = JSON.parse(response.content)["download_url"].as_s
    get_response = HTTP::Client.get(download_url)
    get_response.status_code.should eq 200
    get_response.body.should eq "hello"
  end

  it "returns 404 for an unknown id" do
    user = create_user

    response = Marten::Spec.client.get(
      Marten.routes.reverse("uploaded_file_download_url", id: UUID.random),
      headers: auth_headers_for(user)
    )

    response.status.should eq 404
  end

  it "returns 404 for an expired file" do
    user = create_user
    uploaded = Ligo::UploadedFile.create_opaque!(
      byte_size: 5_i64,
      uploaded_by: user,
      expires_at: Time.local - 1.minute,
    )

    response = Marten::Spec.client.get(
      Marten.routes.reverse("uploaded_file_download_url", id: uploaded.id),
      headers: auth_headers_for(user)
    )

    response.status.should eq 404
  end

  it "returns 404 when presigned upload is disabled" do
    AppSettings.instance.ligo_allow_presigned_upload = false
    user = create_user

    response = Marten::Spec.client.get(
      Marten.routes.reverse("uploaded_file_download_url", id: UUID.random),
      headers: auth_headers_for(user)
    )

    response.status.should eq 404
  end
end
