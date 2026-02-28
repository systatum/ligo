require "./spec_helper"

describe FieldMetadata::File do
  describe "#from_json" do
    context "when metadata is malformed" do
      it "rejects negative or zero max_mb value" do
        expect_raises(ArgumentError) do
          FieldMetadata::File.from_json({
            "type"     => "file",
            "many"     => false,
            "max_mb"   => 0.0,
            "ok_mimes" => "*",
          }.to_json)
        end
      end

      it "rejects unreasonable max_mb value" do
        expect_raises(ArgumentError) do
          FieldMetadata::File.from_json({
            "type"     => "file",
            "many"     => false,
            "max_mb"   => 2048.0,
            "ok_mimes" => "*",
          }.to_json)
        end
      end

      it "rejects invalid ok_mimes structure" do
        expect_raises(ArgumentError) do
          FieldMetadata::File.from_json({
            "type"     => "file",
            "many"     => false,
            "max_mb"   => 3.0,
            "ok_mimes" => "invalidtype",
          }.to_json)
        end

        expect_raises(JSON::SerializableError) do
          FieldMetadata::File.from_json({
            "type"     => "file",
            "many"     => true,
            "max_mb"   => 3.0,
            "ok_mimes" => ["image/png"],
          }.to_json)
        end
      end
    end
  end
end
