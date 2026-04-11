require "../../spec_helper"

describe UploadedFileShowHandler do
  describe "#get" do
    it "returns uploaded file binary with cache headers" do
      uploaded_file = create_uploaded_file_metadata(
        content_type: "image/png",
        byte_size: PNG_1X1.bytesize.to_i64
      )
      Marten.media_files_storage.write(uploaded_file.id.to_s, IO::Memory.new(PNG_1X1))

      response = Marten::Spec.client.get(
        Marten.routes.reverse("uploaded_file_show", id: uploaded_file.id.to_s)
      )

      response.status.should eq 200
      response.is_a?(Marten::HTTP::Response::Streaming).should be_true
      response.headers["Content-Length"].should eq PNG_1X1.bytesize.to_s
      response.content_type.should eq "image/png"
      response.headers["Cache-Control"].should eq "public, max-age=604800, immutable"
      response.headers["Last-Modified"].should_not be_empty
    end

    # TODO: might want to implement ETag matching for UploadedFile someday

    it "returns 304 when If-Modified-Since matches Last-Modified" do
      uploaded_file = create_uploaded_file_metadata(
        content_type: "image/png",
        byte_size: PNG_1X1.bytesize.to_i64
      )
      Marten.media_files_storage.write(uploaded_file.id.to_s, IO::Memory.new(PNG_1X1))

      initial_response = Marten::Spec.client.get(
        Marten.routes.reverse("uploaded_file_show", id: uploaded_file.id.to_s)
      )
      last_modified = initial_response.headers["Last-Modified"]

      cached_response = Marten::Spec.client.get(
        Marten.routes.reverse("uploaded_file_show", id: uploaded_file.id.to_s),
        headers: {"If-Modified-Since" => last_modified}
      )

      cached_response.status.should eq 304
      cached_response.content.should eq ""
      cached_response.headers["Last-Modified"].should eq last_modified
      cached_response.headers["Cache-Control"].should eq "public, max-age=604800, immutable"
    end

    it "returns 404 when file metadata is missing" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("uploaded_file_show", id: UUID.random.to_s)
      )

      response.status.should eq 404
    end

    it "returns 404 when file binary is missing from storage" do
      uploaded_file = create_uploaded_file_metadata

      response = Marten::Spec.client.get(
        Marten.routes.reverse("uploaded_file_show", id: uploaded_file.id.to_s)
      )

      response.status.should eq 404
    end
  end
end
