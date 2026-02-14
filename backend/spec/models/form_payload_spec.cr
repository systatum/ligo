require "../spec_helper"

describe FormPayload do
  describe "#initialize" do
    it "parses native and dynamic fields from request data" do
      data = {
        "fields" => {
          "native" => {
            "name" => "Test Name",
          },
          "dynamic" => {
            "field_123" => "Test Value",
            "field_456" => "Another Value",
          },
        },
      }

      payload = FormPayload.new(data)

      payload.native_fields.size.should eq 1
      payload.native_fields["name"].as_s.should eq "Test Name"

      payload.dynamic_fields.size.should eq 2
      payload.dynamic_fields["field_123"].as_s.should eq "Test Value"
      payload.dynamic_fields["field_456"].as_s.should eq "Another Value"
    end

    it "handles empty fields" do
      data = {} of String => String

      payload = FormPayload.new(data)

      payload.native_fields.size.should eq 0
      payload.dynamic_fields.size.should eq 0
    end

    it "handles missing native or dynamic sections" do
      data = {
        "fields" => {
          "dynamic" => {
            "field_1" => "Value",
          },
        },
      }

      payload = FormPayload.new(data)

      payload.native_fields.size.should eq 0
      payload.dynamic_fields.size.should eq 1
    end
  end

  describe "#initialize with JSON string" do
    it "parses JSON string data" do
      json_string = %({
        "fields": {
          "native": {
            "title": "My Title"
          },
          "dynamic": {
            "field_abc": "Content"
          }
        }
      })

      payload = FormPayload.new(json_string)

      payload.native_fields["title"].as_s.should eq "My Title"
      payload.dynamic_fields["field_abc"].as_s.should eq "Content"
    end
  end
end
