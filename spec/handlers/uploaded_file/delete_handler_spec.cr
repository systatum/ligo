require "./spec_helper"

describe UploadedFileDeleteHandler do
  after_each do
    AppSettings.instance.ligo_allow_presigned_upload = true
  end

  it "deletes the object from storage and the row" do
    user = create_user
    uploaded = Ligo::UploadedFile.create_opaque!(byte_size: 5_i64, uploaded_by: user)
    bucket = AppSettings.instance.ligo_uploaded_file_bucket
    put_url = S3PresignerService.presigned_put_url(bucket, uploaded.id.to_s)
    HTTP::Client.put(put_url, body: "hello").status_code.should eq 200

    response = Marten::Spec.client.delete(
      Marten.routes.reverse("uploaded_file_delete", id: uploaded.id),
      headers: auth_headers_for(user)
    )

    response.status.should eq 204
    Ligo::UploadedFile.get(id: uploaded.id).should be_nil

    get_url = S3PresignerService.presigned_get_url(bucket, uploaded.id.to_s)
    HTTP::Client.get(get_url).status_code.should eq 404
  end

  it "returns 404 for an unknown id" do
    user = create_user

    response = Marten::Spec.client.delete(
      Marten.routes.reverse("uploaded_file_delete", id: UUID.random),
      headers: auth_headers_for(user)
    )

    response.status.should eq 404
  end

  it "returns 404 when presigned upload is disabled" do
    AppSettings.instance.ligo_allow_presigned_upload = false
    user = create_user

    response = Marten::Spec.client.delete(
      Marten.routes.reverse("uploaded_file_delete", id: UUID.random),
      headers: auth_headers_for(user)
    )

    response.status.should eq 404
  end
end
