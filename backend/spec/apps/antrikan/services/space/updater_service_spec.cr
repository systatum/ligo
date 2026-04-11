require "./spec_helper.cr"

describe Antrikan::Space::UpdaterService do
  describe "#run" do
    context "with valid attributes" do
      it "updates the space attributes successfully" do
        space = create_space

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["name"] = ["Updated Name"]
        raw_hash["need_manual_approval"] = [JSON.parse("true")]
        raw_hash["has_operating_hours"] = [JSON.parse("false")]

        data = Marten::HTTP::Params::Data.new(raw_hash)

        result = Antrikan::Space::UpdaterService.new(space, data).run

        result.success?.should be_true

        updated_space = result.data.not_nil!
        updated_space.name.should eq "Updated Name"
        updated_space.need_manual_approval.should eq true
        updated_space.has_operating_hours.should eq false
      end
    end

    context "with invalid schema" do
      it "returns failure if the schema is invalid" do
        space = create_space

        raw_hash = Marten::HTTP::Params::Data::RawHash.new
        raw_hash["name"] = [""] # Name is required

        data = Marten::HTTP::Params::Data.new(raw_hash)

        result = Antrikan::Space::UpdaterService.new(space, data).run

        result.success?.should be_false
        result.errors.should_not be_nil
      end
    end

    context "when logo data is provided" do
      context "with valid image payload" do
        it "handles logo upload and assigns logo_file_id" do
          space = create_space

          logo_payload = {
            "base64_bytes" => Base64.encode(PNG_1X1),
            "mimetype"     => "image/png",
          }

          raw_hash = Marten::HTTP::Params::Data::RawHash.new
          raw_hash["name"] = ["Space with logo"]
          raw_hash["logo"] = [JSON.parse(logo_payload.to_json)]

          data = Marten::HTTP::Params::Data.new(raw_hash)

          result = Antrikan::Space::UpdaterService.new(space, data).run

          result.success?.should be_true

          space.reload
          space.logo_file_id.should_not be_nil
        end
      end

      context "with non-image mimetype" do
        it "rejects non-image media types" do
          space = create_space

          logo_payload = {
            "base64_bytes" => Base64.encode("not-an-image"),
            "mimetype"     => "application/pdf",
          }

          raw_hash = Marten::HTTP::Params::Data::RawHash.new
          raw_hash["name"] = ["Space with invalid logo"]
          raw_hash["logo"] = [JSON.parse(logo_payload.to_json)]

          data = Marten::HTTP::Params::Data.new(raw_hash)

          result = Antrikan::Space::UpdaterService.new(space, data).run

          result.success?.should be_false
          result.errors.should_not be_nil
          result.errors.not_nil![0].message.should eq "must be an image (image/*)"
        end
      end

      context "with invalid image content" do
        it "rejects invalid image content even when mimetype is image" do
          space = create_space

          logo_payload = {
            "base64_bytes" => Base64.encode("not-an-image"),
            "mimetype"     => "image/png",
          }

          raw_hash = Marten::HTTP::Params::Data::RawHash.new
          raw_hash["name"] = ["Space with invalid logo"]
          raw_hash["logo"] = [JSON.parse(logo_payload.to_json)]

          data = Marten::HTTP::Params::Data.new(raw_hash)

          result = Antrikan::Space::UpdaterService.new(space, data).run

          result.success?.should be_false
          result.errors.should_not be_nil
        end
      end
    end
  end
end
