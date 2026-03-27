require "./spec_helper.cr"

describe FileStagerService do
  describe "#run" do
    it "returns success for a valid PNG payload" do
      payload = FilePayload.from_json({
        "base64_bytes" => Base64.encode(PNG_1X1),
        "mimetype"     => "image/png",
      }.to_json)

      result = FileStagerService.new(payload).run

      result.success?.should be_true

      uploaded = result.data.not_nil!
      uploaded.size.should eq PNG_1X1.bytesize
      uploaded.io.gets_to_end.should eq PNG_1X1
    end

    it "returns failure for invalid base64 payload" do
      payload = FilePayload.from_json({
        "base64_bytes" => "not_base64!!",
        "mimetype"     => "image/png",
      }.to_json)

      result = FileStagerService.new(payload).run

      result.failure?.should be_true
      result.errors.should_not be_nil
      result.errors.not_nil!.size.should be > 0
    end

    it "returns failure when image content doesn't match mimetype" do
      payload = FilePayload.from_json({
        "base64_bytes" => Base64.encode("not an image"),
        "mimetype"     => "image/png",
      }.to_json)

      result = FileStagerService.new(payload).run

      result.failure?.should be_true
      result.errors.should_not be_nil
      result.errors.not_nil!.size.should be > 0
    end
  end
end
