require "../../spec_helper"

describe FieldValueConcerns::Updater do
  before_each do
    FieldDefinition.all.delete
    FieldValue.all.delete
    Workaty::EmailTemplate.all.delete
  end

  describe "#update!" do
    context "when field values does not exist" do
      it "creates new ones" do
        user = create_user
        template = create_email_template(adder: user)

        field_def = FieldDefinition.new(
          name: "title",
          resource_type: FieldResourceType::EMAIL_TEMPLATE,
          data_type: FieldDataType::DTYPE_STRING,
          nullable: false
        )
        field_def.save!

        json_data = %({
        "fields": {
          "dynamic": {
            "#{field_def.hashed_id}": "My Template Title"
          }
        }
      })

        form = FormPayload.new(json_data)
        FieldValue.update!(template, form, FieldResourceType::EMAIL_TEMPLATE).should be_true

        field_value = FieldValue.for_resource_field(
          "title",
          template.id.as(Int64),
          FieldResourceType::EMAIL_TEMPLATE
        )

        field_value.should_not be_nil
        field_value.not_nil!.string_value.should eq "My Template Title"
      end

      it "ignores fields that don't match resource type" do
        user = create_user
        template = create_email_template(adder: user)

        wrong_field = FieldDefinition.new(
          name: "first_name",
          resource_type: FieldResourceType::CANDIDATE,
          data_type: FieldDataType::DTYPE_STRING
        )
        wrong_field.save!

        json_data = %({
        "fields": {
          "dynamic": {
            "#{wrong_field.hashed_id}": "Should Be Ignored"
          }
        }
      })

        form = FormPayload.new(json_data)
        FieldValue.update!(template, form, FieldResourceType::EMAIL_TEMPLATE)

        count = FieldValue.filter(
          resource_id: template.id.as(Int64),
          resource_type: FieldResourceType::EMAIL_TEMPLATE
        ).count

        count.should eq 0
      end
    end

    context "when field values does exist" do
      it "updates existing ones" do
        user = create_user
        template = create_email_template(adder: user)

        field_def = FieldDefinition.new(
          name: "content",
          resource_type: FieldResourceType::EMAIL_TEMPLATE,
          data_type: FieldDataType::DTYPE_TEXT_RICH,
          nullable: false
        )
        field_def.save!

        fv = FieldValue.new(
          field: field_def,
          resource_id: template.id.as(Int64),
          resource_type: FieldResourceType::EMAIL_TEMPLATE,
          string_value: "Initial Content"
        )
        fv.save!

        json_data = %({
        "fields": {
          "dynamic": {
            "#{field_def.hashed_id}": "Updated Content"
          }
        }
      })

        form = FormPayload.new(json_data)
        FieldValue.update!(template, form, FieldResourceType::EMAIL_TEMPLATE)

        fv.reload
        fv.string_value.should eq "Updated Content"
      end
    end
  end
end
