require "./spec_helper"

describe FieldMetadata::Choice do
  describe "#from_json" do
    context "when metadata is malformed" do
      it "throws on missing options" do
        expect_raises(JSON::SerializableError) do
          FieldMetadata::Choice.from_json({
            "type"    => "choice",
            "default" => "a",
          }.to_json)
        end
      end

      it "rejects bad default" do
        expect_raises(ArgumentError) do
          options = [
            {"id" => "a", "caption" => {"en" => "A"}},
          ]
          FieldMetadata::Choice.from_json({
            "type"    => "choice",
            "options" => options,
            "default" => "b",
          }.to_json)
        end
      end
    end
  end
end
