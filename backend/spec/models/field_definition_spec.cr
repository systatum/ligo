require "../spec_helper"

describe FieldDefinition do
  describe "#new" do
    context "when creating a field with default values" do
      it "sets default attributes" do
        field = FieldDefinition.new(
          name: "first_name",
          resource_type: FieldResourceType::CANDIDATE,
          data_type: FieldDataType::DTYPE_STRING
        )

        field.is_system_field.should be_false
        field.nullable.should be_true
        field.uniqueness.should eq FieldUniqueness::UNIQUELESS
      end
    end

    context "when generating a hashed ID when saved" do
      it "creates a hashed_id" do
        field = FieldDefinition.new(
          name: "email",
          resource_type: FieldResourceType::USER,
          data_type: FieldDataType::DTYPE_STRING
        )
        field.save!

        field.hashed_id.should_not be_nil
        field.hashed_id.size.should be >= 12
      end
    end
  end

  describe "#localized_name" do
    context "when creating a field with localized name" do
      it "saves and loads localized names" do
        localized_name = LocalizedName.new(
          english: "First Name",
          indonesian: "Nama Depan",
          japanese: "名"
        )
        field = FieldDefinition.new(
          name: "first_name",
          resource_type: FieldResourceType::CANDIDATE,
          data_type: FieldDataType::DTYPE_STRING,
          localized_name: localized_name
        )
        field.save!

        field.localized_name.should_not be_nil
        field.localized_name.try(&.english).should eq "First Name"
      end
    end

    context "when returning proper localized name based on locale" do
      it "returns correct value for each locale" do
        localized_name = LocalizedName.new(
          english: "First Name",
          indonesian: "Nama Depan",
          japanese: "名"
        )
        field = FieldDefinition.new(
          name: "first_name",
          resource_type: FieldResourceType::CANDIDATE,
          data_type: FieldDataType::DTYPE_STRING,
          localized_name: localized_name
        )
        field.localized_name.try(&.english).should eq "First Name"
        field.localized_name.try(&.indonesian).should eq "Nama Depan"
        field.localized_name.try(&.japanese).should eq "名"
      end
    end

    context "when falling back to field name when no localized name" do
      it "returns nil for missing localized_name" do
        field = FieldDefinition.new(
          name: "first_name",
          resource_type: FieldResourceType::CANDIDATE,
          data_type: FieldDataType::DTYPE_STRING,
        )

        field.localized_name.should be_nil
      end
    end
  end

  describe "#can_be_deleted?" do
    context "when system field" do
      it "returns false" do
        system_field = FieldDefinition.new(
          name: "id",
          resource_type: FieldResourceType::USER,
          data_type: FieldDataType::DTYPE_INT,
          is_system_field: true
        )
        system_field.save!
        system_field.can_be_deleted?.should be_false
      end
    end

    context "when user-defined field" do
      it "returns true" do
        user_field = FieldDefinition.new(
          name: "custom_field",
          resource_type: FieldResourceType::USER,
          data_type: FieldDataType::DTYPE_STRING,
          is_system_field: false
        )
        user_field.save!
        user_field.can_be_deleted?.should be_true
      end
    end
  end

  describe "#can_be_renamed?" do
    context "when system field" do
      it "returns false" do
        system_field = FieldDefinition.new(
          name: "id",
          resource_type: FieldResourceType::USER,
          data_type: FieldDataType::DTYPE_INT,
          is_system_field: true
        )
        system_field.save!
        system_field.can_be_renamed?.should be_false
      end
    end

    context "when user-defined field" do
      it "returns true" do
        user_field = FieldDefinition.new(
          name: "custom_field",
          resource_type: FieldResourceType::USER,
          data_type: FieldDataType::DTYPE_STRING,
          is_system_field: false
        )
        user_field.save!
        user_field.can_be_renamed?.should be_true
      end
    end
  end

  describe "#delete" do
    context "when system field" do
      it "raises error" do
        system_field = FieldDefinition.new(
          name: "id",
          resource_type: FieldResourceType::USER,
          data_type: FieldDataType::DTYPE_INT,
          is_system_field: true
        )
        system_field.save!
        expect_raises(Exception, "System fields cannot be deleted") do
          system_field.delete
        end
      end
    end

    context "when user-defined field" do
      it "deletes successfully" do
        user_field = FieldDefinition.new(
          name: "custom_field",
          resource_type: FieldResourceType::USER,
          data_type: FieldDataType::DTYPE_STRING,
          is_system_field: false
        )
        user_field.save!
        user_field.delete.should eq 1
      end
    end
  end

  describe "#save" do
    it "prevents renaming" do
      system_field = FieldDefinition.new(
        name: "id",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_INT,
        is_system_field: true
      )
      system_field.save!
      system_field.name = "new_id"
      system_field.save.should be_false
      system_field.errors.any? { |error| error.message.includes?("cannot be changed for system fields") }.should be_true
    end
  end

  describe ".for_resource_type" do
    it "returns only matching fields" do
      user_field = FieldDefinition.new(
        name: "username",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING
      )
      user_field.save!

      candidate_field = FieldDefinition.new(
        name: "resume",
        resource_type: FieldResourceType::CANDIDATE,
        data_type: FieldDataType::DTYPE_STRING
      )
      candidate_field.save!

      user_fields = FieldDefinition.for_resource_type(FieldResourceType::USER)
      user_fields.count.should eq 1
      user_fields.first!.name.should eq "username"
    end
  end

  describe ".system_fields" do
    it "returns only system fields" do
      system_field = FieldDefinition.new(
        name: "id",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_INT,
        is_system_field: true
      )
      system_field.save!

      user_field = FieldDefinition.new(
        name: "custom_field",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false
      )
      user_field.save!

      system_fields = FieldDefinition.system_fields
      system_fields.count.should eq 1
      system_fields.first!.name.should eq "id"
    end
  end

  describe ".user_fields" do
    it "returns only user fields" do
      system_field = FieldDefinition.new(
        name: "id",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_INT,
        is_system_field: true
      )
      system_field.save!

      user_field = FieldDefinition.new(
        name: "custom_field",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false
      )
      user_field.save!

      user_fields = FieldDefinition.user_fields
      user_fields.count.should eq 1
      user_fields.first!.name.should eq "custom_field"
    end
  end

  describe "#find_by_name_and_resource_type" do
    it "returns correct field or nil" do
      field = FieldDefinition.new(
        name: "email",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING
      )
      field.save!

      found_field = FieldDefinition.find_by_name_and_resource_type("email", FieldResourceType::USER)
      found_field.should_not be_nil
      found_field.try(&.name).should eq "email"

      not_found = FieldDefinition.find_by_name_and_resource_type("email", FieldResourceType::CANDIDATE)
      not_found.should be_nil
    end
  end

  describe "#soft_delete" do
    it "hides soft deleted fields from default queries" do
      field = FieldDefinition.new(
        name: "test_field",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING
      )
      field.save!

      field.soft_delete

      FieldDefinition.get(id: field.id).should be_nil

      FieldDefinition.unscoped.get(id: field.id).should_not be_nil
      FieldDefinition.unscoped.get(id: field.id).try(&.deleted_at).should_not be_nil
    end
  end

  describe "#system_field?" do
    it "returns true for system field" do
      system_field = FieldDefinition.new(
        name: "id",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_INT,
        is_system_field: true
      )
      system_field.system_field?.should be_true
    end
  end

  describe "#user_field?" do
    it "returns true for user field" do
      user_field = FieldDefinition.new(
        name: "custom_field",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING,
        is_system_field: false
      )
      user_field.user_field?.should be_true
    end
  end

  describe "#value" do
    context "when having proper resource type enum values" do
      it "matches expected values" do
        FieldResourceType::USER.value.should eq 1
        FieldResourceType::CANDIDATE.value.should eq 2
      end
    end

    context "when having proper data type enum values" do
      it "matches expected values" do
        FieldDataType::DTYPE_STRING.value.should eq 0
        FieldDataType::DTYPE_INT.value.should eq 1
        FieldDataType::DTYPE_FLOAT.value.should eq 2
        FieldDataType::DTYPE_DATE.value.should eq 3
        FieldDataType::DTYPE_TIME.value.should eq 4
        FieldDataType::DTYPE_DATETIME.value.should eq 5
        FieldDataType::DTYPE_BOOLEAN.value.should eq 6
      end
    end

    context "when having proper uniqueness enum values" do
      it "matches expected values" do
        FieldUniqueness::UNIQUELESS.value.should eq 0
        FieldUniqueness::UNIQUE_ALWAYS.value.should eq 1
        FieldUniqueness::UNIQUE_FILL.value.should eq 2
      end
    end
  end

  describe "#save" do
    it "prevents duplicate names for same resource type" do
      FieldDefinition.new(
        name: "email",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING
      ).save!

      duplicate_field = FieldDefinition.new(
        name: "email",
        resource_type: FieldResourceType::USER,
        data_type: FieldDataType::DTYPE_STRING
      )
      duplicate_field.save.should be_false

      different_resource_field = FieldDefinition.new(
        name: "email",
        resource_type: FieldResourceType::CANDIDATE,
        data_type: FieldDataType::DTYPE_STRING
      )
      different_resource_field.save.should be_true
    end
  end
end
