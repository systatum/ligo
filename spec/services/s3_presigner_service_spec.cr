require "../spec_helper"

describe S3PresignerService do
  bucket = "ligo-uploaded-files-test"

  it "round-trips a PUT followed by a GET" do
    key = UUID.random.to_s

    put_url = S3PresignerService.presigned_put_url(bucket, key)
    HTTP::Client.put(put_url, body: "hello world").status_code.should eq 200

    get_url = S3PresignerService.presigned_get_url(bucket, key)
    response = HTTP::Client.get(get_url)
    response.status_code.should eq 200
    response.body.should eq "hello world"
  end

  it "removes the object on delete" do
    key = UUID.random.to_s
    HTTP::Client.put(S3PresignerService.presigned_put_url(bucket, key), body: "x")

    S3PresignerService.delete_object(bucket, key)

    get_response = HTTP::Client.get(S3PresignerService.presigned_get_url(bucket, key))
    get_response.status_code.should eq 404
  end
end
