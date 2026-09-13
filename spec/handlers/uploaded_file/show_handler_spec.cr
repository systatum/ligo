require "../../spec_helper"

PNG_BASE64 = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="

describe UploadedFileShowHandler do
  it "returns the uploaded file content with a matching content type" do
    user = create_user
    payload = FilePayload.from_json(%({"base64_bytes": "#{PNG_BASE64}", "mimetype": "image/png"}))
    staged = FileStagerService.new(payload).run.data.not_nil!
    uploaded = FileCommitterService.new(staged, user).run.data.not_nil!

    response = Marten::Spec.client.get(Marten.routes.reverse("uploaded_file_show", id: uploaded.id))

    response.status.should eq 200
    response.headers["Content-Type"].should eq "image/png"
    response.headers["Content-Length"].should eq uploaded.byte_size.to_s
  end

  it "returns 404 for an unknown file id" do
    response = Marten::Spec.client.get(Marten.routes.reverse("uploaded_file_show", id: UUID.random))

    response.status.should eq 404
  end

  it "returns 304 when If-Modified-Since matches the file's last update" do
    user = create_user
    payload = FilePayload.from_json(%({"base64_bytes": "#{PNG_BASE64}", "mimetype": "image/png"}))
    staged = FileStagerService.new(payload).run.data.not_nil!
    uploaded = FileCommitterService.new(staged, user).run.data.not_nil!

    response = Marten::Spec.client.get(
      Marten.routes.reverse("uploaded_file_show", id: uploaded.id),
      headers: {"If-Modified-Since" => HTTP.format_time(uploaded.updated_at.not_nil!.to_utc)}
    )

    response.status.should eq 304
  end
end
