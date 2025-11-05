require "../spec_helper"

describe FieldValue do
  describe "#new" do
    it "creates a field value with string data" do
      field = create_field("first_name", FieldDataType::DTYPE_STRING)

      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        string_value: "John Doe"
      )

      field_value.string_value.should eq "John Doe"
      field_value.resource_id.should eq 1
      field_value.resource_type.should eq FieldResourceType::CANDIDATE
    end

    it "creates a field value with integer data" do
      field = create_field("age", FieldDataType::DTYPE_INT)

      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        integer_value: 25
      )

      field_value.integer_value.should eq 25
    end

    it "creates a field value with float data" do
      field = create_field("salary", FieldDataType::DTYPE_FLOAT)

      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        float_value: 50000.50
      )

      field_value.float_value.should eq 50000.50
    end

    it "creates a field value with date data" do
      field = create_field("birth_date", FieldDataType::DTYPE_DATE)
      date = Time.utc

      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        date_value: date
      )

      field_value.date_value.should eq date
    end

    it "creates a field value with datetime data" do
      field = create_field("created_at", FieldDataType::DTYPE_DATETIME)
      datetime = Time.utc

      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        datetime_value: datetime
      )

      field_value.datetime_value.should eq datetime
    end

    it "creates a field value with boolean data" do
      field = create_field("is_active", FieldDataType::DTYPE_BOOLEAN)

      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        boolean_value: true
      )

      field_value.boolean_value.should be_true
    end
  end

  describe "#value" do
    it "returns the correct value based on field data type" do
      string_field = create_field("first_name", FieldDataType::DTYPE_STRING)
      string_value = FieldValue.new(
        field_id: string_field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        string_value: "John Doe"
      )
      string_value.value(string_field.data_type!).should eq "John Doe"

      integer_field = create_field("age", FieldDataType::DTYPE_INT)
      integer_value = FieldValue.new(
        field_id: integer_field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        integer_value: 25
      )
      integer_value.value(integer_field.data_type!).should eq 25

      float_field = create_field("salary", FieldDataType::DTYPE_FLOAT)
      float_value = FieldValue.new(
        field_id: float_field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        float_value: 50000.50
      )
      float_value.value(float_field.data_type!).should eq 50000.50

      boolean_field = create_field("is_active", FieldDataType::DTYPE_BOOLEAN)
      boolean_value = FieldValue.new(
        field_id: boolean_field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        boolean_value: true
      )
      boolean_value.value(boolean_field.data_type!).should be_true
    end
  end

  describe "#set_value" do
    it "sets the correct value based on field data type" do
      field = create_field("first_name", FieldDataType::DTYPE_STRING)
      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE
      )

      field_value.set_value("Jane Doe", field.data_type!)
      field_value.string_value.should eq "Jane Doe"
      field_value.integer_value.should be_nil
      field_value.float_value.should be_nil
      field_value.date_value.should be_nil
      field_value.datetime_value.should be_nil
      field_value.boolean_value.should be_nil
    end

    it "sets integer value correctly" do
      field = create_field("age", FieldDataType::DTYPE_INT)
      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE
      )

      field_value.set_value(30, field.data_type!)
      field_value.integer_value.should eq 30
      field_value.string_value.should be_nil
    end

    it "sets float value correctly" do
      field = create_field("salary", FieldDataType::DTYPE_FLOAT)
      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE
      )

      field_value.set_value(75000.75, field.data_type!)
      field_value.float_value.should eq 75000.75
      field_value.string_value.should be_nil
    end

    it "sets boolean value correctly" do
      field = create_field("is_active", FieldDataType::DTYPE_BOOLEAN)
      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE
      )

      field_value.set_value(false, field.data_type!)
      field_value.boolean_value.should be_false
      field_value.string_value.should be_nil
    end
  end

  context "validations" do
    it "validates that no value columns are populated" do
      field = create_field("first_name", FieldDataType::DTYPE_STRING)
      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE
      )

      field_value.save.should be_true
    end

    it "validates unique field per resource" do
      field = create_field("first_name", FieldDataType::DTYPE_STRING)
      FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        string_value: "John Doe"
      ).tap(&.save!)

      duplicate_field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        string_value: "Jane Doe"
      )

      duplicate_field_value.save.should be_false
      duplicate_field_value.errors.any? { |error| error.message.includes?("Only one value per field per resource is allowed") }.should be_true
    end
  end

  describe "#search" do
    before_each do
      field = create_field("first_name", FieldDataType::DTYPE_STRING)
      FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        string_value: "John Doe"
      ).tap(&.save!)

      FieldValue.new(
        field_id: field.id!,
        resource_id: 2,
        resource_type: FieldResourceType::CANDIDATE,
        string_value: "Jane Smith"
      ).tap(&.save!)

      user_field = create_field("username", FieldDataType::DTYPE_STRING)
      FieldValue.new(
        field_id: user_field.id!,
        resource_id: 3,
        resource_type: FieldResourceType::USER,
        string_value: "John Admin"
      ).tap(&.save!)
    end

    it "searches across all field values" do
      results = FieldValue.search("John")
      results.count.should eq 2

      result_names = results.map(&.string_value).compact
      result_names.should contain("John Doe")
      result_names.should contain("John Admin")
    end

    it "searches within specific resource types" do
      results = FieldValue.search("John", [FieldResourceType::CANDIDATE])
      results.count.should eq 1
      results.first!.resource_id.should eq 1

      result_names = results.map(&.string_value).compact
      result_names.should contain("John Doe")
    end

    it "returns empty results for non-matching query" do
      results = FieldValue.search("NonExistent")
      results.count.should eq 0
    end
  end

  describe "#for_resource" do
    before_each do
      field = create_field("first_name", FieldDataType::DTYPE_STRING)
      FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        string_value: "John Doe"
      ).tap(&.save!)

      integer_field = create_field("age", FieldDataType::DTYPE_INT)
      FieldValue.new(
        field_id: integer_field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        integer_value: 25
      ).tap(&.save!)
    end

    it "gets all field values for a specific resource" do
      values = FieldValue.for_resource(FieldResourceType::CANDIDATE, 1)
      values.count.should eq 2
    end

    it "gets field value by field name for a specific resource" do
      value = FieldValue.for_resource_field(
        FieldResourceType::CANDIDATE,
        1,
        "first_name"
      )
      value.should_not be_nil
      value.try(&.string_value).should eq "John Doe"
    end

    it "returns nil for non-existent field name" do
      value = FieldValue.for_resource_field(
        FieldResourceType::CANDIDATE,
        1,
        "non_existent"
      )
      value.should be_nil
    end
  end

  describe "#soft_delete" do
    it "soft deletes field values" do
      field = create_field("first_name", FieldDataType::DTYPE_STRING)
      field_value = FieldValue.new(
        field_id: field.id!,
        resource_id: 1,
        resource_type: FieldResourceType::CANDIDATE,
        string_value: "John Doe"
      )
      field_value.save!

      field_value.soft_delete

      FieldValue.get(id: field_value.id).should be_nil

      FieldValue.unscoped.get(id: field_value.id).should_not be_nil
      FieldValue.unscoped.get(id: field_value.id).try(&.deleted_at).should_not be_nil
    end
  end

  context "uniqueness logic" do
    it "allows duplicate values when uniqueness is UNIQUELESS" do
      field = FieldDefinition.new(
        name: "nickname",
        resource_type: FieldResourceType::CANDIDATE,
        data_type: FieldDataType::DTYPE_STRING,
        uniqueness: FieldUniqueness::UNIQUELESS
      )
      field.save!
      fv1 = FieldValue.new(field_id: field.id!, resource_id: 1, resource_type: FieldResourceType::CANDIDATE, string_value: "foo")
      fv2 = FieldValue.new(field_id: field.id!, resource_id: 2, resource_type: FieldResourceType::CANDIDATE, string_value: "foo")
      fv1.save!.should be_true
      fv2.save!.should be_true
    end

    it "enforces uniqueness across all resources when uniqueness is UNIQUE_ALWAYS" do
      field = FieldDefinition.new(
        name: "passport",
        resource_type: FieldResourceType::CANDIDATE,
        data_type: FieldDataType::DTYPE_STRING,
        uniqueness: FieldUniqueness::UNIQUE_ALWAYS
      )
      field.save!
      fv1 = FieldValue.new(field_id: field.id!, resource_id: 1, resource_type: FieldResourceType::CANDIDATE, string_value: "A123")
      fv1.save!.should be_true
      fv2 = FieldValue.new(field_id: field.id!, resource_id: 2, resource_type: FieldResourceType::CANDIDATE, string_value: "A123")
      fv2.save.should be_false
      fv2.errors.any? { |e| e.message.includes?("Value must be unique") }.should be_true
    end

    it "enforces uniqueness only for non-blank values when uniqueness is UNIQUE_FILL" do
      field = FieldDefinition.new(
        name: "optional_id",
        resource_type: FieldResourceType::CANDIDATE,
        data_type: FieldDataType::DTYPE_STRING,
        uniqueness: FieldUniqueness::UNIQUE_FILL
      )
      field.save!
      fv1 = FieldValue.new(field_id: field.id!, resource_id: 1, resource_type: FieldResourceType::CANDIDATE, string_value: "X999")
      fv1.save!.should be_true
      fv2 = FieldValue.new(field_id: field.id!, resource_id: 2, resource_type: FieldResourceType::CANDIDATE, string_value: "X999")
      fv2.save.should be_false
      fv2.errors.any? { |e| e.message.includes?("Value must be unique") }.should be_true
      fv3 = FieldValue.new(field_id: field.id!, resource_id: 3, resource_type: FieldResourceType::CANDIDATE, string_value: nil)
      fv3.save.should be_true
      fv4 = FieldValue.new(field_id: field.id!, resource_id: 4, resource_type: FieldResourceType::CANDIDATE, string_value: nil)
      fv4.save.should be_true
    end
  end
end
