require "../spec_helper"

describe SystemFieldsMigrator do
  original_fields = [] of SystemFieldsMigrator::FieldDefinitionConfig

  before_each do
    original_fields = SystemFieldsMigrator.fields.dup

    FieldDefinition.filter(name__startswith: "test_").delete
    SystemFieldsMigrator.clear!
  end

  after_each do
    SystemFieldsMigrator.clear!
    original_fields.each do |field_config|
      SystemFieldsMigrator.fields << field_config
    end
  end

  describe "#add_field!" do
    it "registers a field definition" do
      SystemFieldsMigrator.add_field!(
        name: "test_field",
        to: FieldResourceType::CANDIDATE,
        data_type: FieldDataType::DTYPE_STRING
      )

      SystemFieldsMigrator.fields.size.should eq(1)
      config = SystemFieldsMigrator.fields.first
      config.name.should eq("test_field")
      config.resource_type.should eq(FieldResourceType::CANDIDATE)
      config.data_type.should eq(FieldDataType::DTYPE_STRING)
    end
  end

  describe "#add_string_field!" do
    it "registers a string field" do
      localized = LocalizedName.new(
        english: "Test Field",
        indonesian: "Bidang Tes"
      )

      SystemFieldsMigrator.add_string_field!(
        "test_string",
        to: FieldResourceType::CANDIDATE,
        localized_name: localized,
        nullable: false
      )

      config = SystemFieldsMigrator.fields.first
      config.data_type.should eq(FieldDataType::DTYPE_STRING)
      config.nullable.should eq(false)
    end
  end

  describe "#add_int_field!" do
    it "registers an integer field" do
      SystemFieldsMigrator.add_int_field!(
        "test_int",
        to: FieldResourceType::CANDIDATE
      )

      config = SystemFieldsMigrator.fields.first
      config.data_type.should eq(FieldDataType::DTYPE_INT)
    end
  end

  describe "#add_boolean_field!" do
    it "registers a boolean field" do
      SystemFieldsMigrator.add_boolean_field!(
        "test_bool",
        to: FieldResourceType::CANDIDATE
      )

      config = SystemFieldsMigrator.fields.first
      config.data_type.should eq(FieldDataType::DTYPE_BOOLEAN)
    end
  end

  describe "#migrate!" do
    context "when field doesn't exist" do
      it "creates a new system field" do
        SystemFieldsMigrator.add_string_field!(
          "test_new_field",
          to: FieldResourceType::CANDIDATE,
          localized_name: LocalizedName.new(english: "Test"),
          nullable: false
        )

        existing = FieldDefinition.find_by_name_and_resource_type(
          "test_new_field",
          FieldResourceType::CANDIDATE
        )
        existing.should be_nil

        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type(
          "test_new_field",
          FieldResourceType::CANDIDATE
        )
        field.should_not be_nil
        field.not_nil!.is_system_field.should be_true
        field.not_nil!.nullable.should eq(false)
        field.not_nil!.data_type_enum.should eq(FieldDataType::DTYPE_STRING)
      end
    end

    context "when field exists" do
      it "updates existing field properties" do
        field = FieldDefinition.new(
          name: "test_existing",
          resource_type: FieldResourceType::CANDIDATE,
          data_type: FieldDataType::DTYPE_STRING,
          nullable: true,
          is_system_field: true,
          localized_name: nil
        )
        field.save!

        SystemFieldsMigrator.add_string_field!(
          "test_existing",
          to: FieldResourceType::CANDIDATE,
          localized_name: LocalizedName.new(english: "Updated Name"),
          nullable: false,
          uniqueness: FieldUniqueness::UNIQUE_ALWAYS
        )

        SystemFieldsMigrator.migrate!

        updated_field = FieldDefinition.find_by_name_and_resource_type(
          "test_existing",
          FieldResourceType::CANDIDATE
        )
        updated_field.not_nil!.nullable.should eq(false)
        updated_field.not_nil!.uniqueness.should eq(FieldUniqueness::UNIQUE_ALWAYS)
        updated_field.not_nil!.localized_name.should_not be_nil
        updated_field.not_nil!.localized_name_english.not_nil!.should eq("Updated Name")
      end

      it "marks non-system field as system field" do
        field = FieldDefinition.new(
          name: "test_convert",
          resource_type: FieldResourceType::CANDIDATE,
          data_type: FieldDataType::DTYPE_STRING,
          is_system_field: false,
          localized_name: nil
        )
        field.save!

        SystemFieldsMigrator.add_string_field!(
          "test_convert",
          to: FieldResourceType::CANDIDATE
        )

        SystemFieldsMigrator.migrate!

        updated_field = FieldDefinition.find_by_name_and_resource_type(
          "test_convert",
          FieldResourceType::CANDIDATE
        )
        updated_field.not_nil!.is_system_field.should be_true
      end

      it "doesn't update field if no changes needed" do
        localized = LocalizedName.new(english: "Test")
        field = FieldDefinition.new(
          name: "test_unchanged",
          resource_type: FieldResourceType::CANDIDATE,
          data_type: FieldDataType::DTYPE_STRING,
          nullable: true,
          is_system_field: true,
          localized_name: localized
        )
        field.save!

        SystemFieldsMigrator.add_string_field!(
          "test_unchanged",
          to: FieldResourceType::CANDIDATE,
          localized_name: localized,
          nullable: true
        )

        SystemFieldsMigrator.migrate!

        unchanged_field = FieldDefinition.find_by_name_and_resource_type(
          "test_unchanged",
          FieldResourceType::CANDIDATE
        )
        unchanged_field.should_not be_nil
      end
    end

    context "with multiple fields" do
      it "migrates all registered fields" do
        SystemFieldsMigrator.add_string_field!(
          "test_multi_1",
          to: FieldResourceType::CANDIDATE
        )
        SystemFieldsMigrator.add_int_field!(
          "test_multi_2",
          to: FieldResourceType::CANDIDATE
        )
        SystemFieldsMigrator.add_boolean_field!(
          "test_multi_3",
          to: FieldResourceType::CANDIDATE
        )

        SystemFieldsMigrator.migrate!

        field1 = FieldDefinition.find_by_name_and_resource_type(
          "test_multi_1",
          FieldResourceType::CANDIDATE
        )
        field2 = FieldDefinition.find_by_name_and_resource_type(
          "test_multi_2",
          FieldResourceType::CANDIDATE
        )
        field3 = FieldDefinition.find_by_name_and_resource_type(
          "test_multi_3",
          FieldResourceType::CANDIDATE
        )

        field1.should_not be_nil
        field2.should_not be_nil
        field3.should_not be_nil
        field1.not_nil!.data_type_enum.should eq(FieldDataType::DTYPE_STRING)
        field2.not_nil!.data_type_enum.should eq(FieldDataType::DTYPE_INT)
        field3.not_nil!.data_type_enum.should eq(FieldDataType::DTYPE_BOOLEAN)
      end
    end
  end

  describe ".clear!" do
    it "clears all registered fields" do
      SystemFieldsMigrator.add_string_field!(
        "test_clear",
        to: FieldResourceType::CANDIDATE
      )
      SystemFieldsMigrator.fields.size.should eq(1)

      SystemFieldsMigrator.clear!
      SystemFieldsMigrator.fields.size.should eq(0)
    end
  end

  describe "#load_from_yaml" do
    it "loads fields from YAML file" do
      yaml_content = <<-YAML
      ---
      CANDIDATE:
        test_yaml_field__str:
          nullable: false
          caption:
            en: Test Field
            id: Bidang Tes
            ja: テストフィールド
        test_number__int:
          nullable: true
          caption:
            en: Test Number
      USER:
        test_email__str:
          nullable: false
          uniqueness: UNIQUE_ALWAYS
          caption:
            en: Email
      YAML

      temp_file = File.tempfile("system_fields", ".yml") do |file|
        file.print(yaml_content)
      end

      begin
        SystemFieldsMigrator.load_from_yaml(temp_file.path)

        fields = SystemFieldsMigrator.fields
        fields.size.should eq(3)

        candidate_fields = fields.select { |f| f.resource_type == FieldResourceType::CANDIDATE }
        candidate_fields.size.should eq(2)

        string_field = candidate_fields.find { |f| f.name == "test_yaml_field" }
        string_field.should_not be_nil
        string_field.not_nil!.data_type.should eq(FieldDataType::DTYPE_STRING)
        string_field.not_nil!.nullable.should eq(false)
        string_field_localized_name = string_field.not_nil!.localized_name.not_nil!
        string_field_localized_name.english.should eq("Test Field")
        string_field_localized_name.indonesian.should eq("Bidang Tes")
        string_field_localized_name.japanese.should eq("テストフィールド")

        int_field = candidate_fields.find { |f| f.name == "test_number" }
        int_field.should_not be_nil
        int_field.not_nil!.data_type.should eq(FieldDataType::DTYPE_INT)
        int_field.not_nil!.nullable.should eq(true)

        user_fields = fields.select { |f| f.resource_type == FieldResourceType::USER }
        user_fields.size.should eq(1)

        email_field = user_fields.first
        email_field.name.should eq("test_email")
        email_field.uniqueness.should eq(FieldUniqueness::UNIQUE_ALWAYS)
      ensure
        temp_file.delete if temp_file
      end
    end

    it "supports all data types with abbreviations" do
      yaml_content = <<-YAML
      ---
      CANDIDATE:
        field_str__str:
          nullable: true
          caption:
            en: String Field
        field_string__string:
          nullable: true
          caption:
            en: String Field Alt
        field_text_rich__text_rich:
          nullable: true
          caption:
            en: Rich Text Field
        field_int__int:
          nullable: true
          caption:
            en: Integer Field
        field_float__float:
          nullable: true
          caption:
            en: Float Field
        field_bool__bool:
          nullable: true
          caption:
            en: Boolean Field
        field_boolean__boolean:
          nullable: true
          caption:
            en: Boolean Field Alt
        field_date__date:
          nullable: true
          caption:
            en: Date Field
        field_time__time:
          nullable: true
          caption:
            en: Time Field
        field_dt__dt:
          nullable: true
          caption:
            en: DateTime Field
        field_datetime__datetime:
          nullable: true
          caption:
            en: DateTime Field Alt
      YAML

      temp_file = File.tempfile("system_fields_types", ".yml") do |file|
        file.print(yaml_content)
      end

      begin
        SystemFieldsMigrator.load_from_yaml(temp_file.path)

        fields = SystemFieldsMigrator.fields
        fields.size.should eq(11)

        fields.find { |f| f.name == "field_str" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_STRING)
        fields.find { |f| f.name == "field_string" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_STRING)
        fields.find { |f| f.name == "field_text_rich" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_TEXT_RICH)
        fields.find { |f| f.name == "field_int" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_INT)
        fields.find { |f| f.name == "field_float" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_FLOAT)
        fields.find { |f| f.name == "field_bool" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_BOOLEAN)
        fields.find { |f| f.name == "field_boolean" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_BOOLEAN)
        fields.find { |f| f.name == "field_date" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_DATE)
        fields.find { |f| f.name == "field_time" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_TIME)
        fields.find { |f| f.name == "field_datetime" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_DATETIME)
        fields.find { |f| f.name == "field_dt" }.not_nil!.data_type.should eq(FieldDataType::DTYPE_DATETIME)
      ensure
        temp_file.delete if temp_file
      end
    end

    it "defaults nullable to true when not specified" do
      yaml_content = <<-YAML
      ---
      CANDIDATE:
        test_default__str:
          caption:
            en: Test
      YAML

      temp_file = File.tempfile("system_fields_default", ".yml") do |file|
        file.print(yaml_content)
      end

      begin
        SystemFieldsMigrator.load_from_yaml(temp_file.path)

        field = SystemFieldsMigrator.fields.first
        field.nullable.should eq(true)
      ensure
        temp_file.delete if temp_file
      end
    end

    it "defaults uniqueness to UNIQUELESS when not specified" do
      yaml_content = <<-YAML
      ---
      CANDIDATE:
        test_unique__str:
          nullable: false
          caption:
            en: Test
      YAML

      temp_file = File.tempfile("system_fields_unique", ".yml") do |file|
        file.print(yaml_content)
      end

      begin
        SystemFieldsMigrator.load_from_yaml(temp_file.path)

        field = SystemFieldsMigrator.fields.first
        field.uniqueness.should eq(FieldUniqueness::UNIQUELESS)
      ensure
        temp_file.delete if temp_file
      end
    end

    it "raises error for invalid field key format" do
      yaml_content = <<-YAML
      ---
      CANDIDATE:
        invalid_field:
          nullable: false
      YAML

      temp_file = File.tempfile("system_fields_invalid", ".yml") do |file|
        file.print(yaml_content)
      end

      begin
        expect_raises(ArgumentError, /Invalid field key format/) do
          SystemFieldsMigrator.load_from_yaml(temp_file.path)
        end
      ensure
        temp_file.delete if temp_file
      end
    end

    it "raises error for unknown data type" do
      yaml_content = <<-YAML
      ---
      CANDIDATE:
        test_field__unknown:
          nullable: false
      YAML

      temp_file = File.tempfile("system_fields_unknown_type", ".yml") do |file|
        file.print(yaml_content)
      end

      begin
        expect_raises(ArgumentError, /Unknown data type/) do
          SystemFieldsMigrator.load_from_yaml(temp_file.path)
        end
      ensure
        temp_file.delete if temp_file
      end
    end

    it "raises error for non-existent file" do
      expect_raises(ArgumentError, /YAML file not found/) do
        SystemFieldsMigrator.load_from_yaml("/non/existent/file.yml")
      end
    end

    it "supports all uniqueness types" do
      yaml_content = <<-YAML
      ---
      CANDIDATE:
        field_uniqueless__str:
          uniqueness: UNIQUELESS
          caption:
            en: Field 1
        field_always__str:
          uniqueness: UNIQUE_ALWAYS
          caption:
            en: Field 2
        field_fill__str:
          uniqueness: UNIQUE_FILL
          caption:
            en: Field 3
      YAML

      temp_file = File.tempfile("system_fields_uniqueness", ".yml") do |file|
        file.print(yaml_content)
      end

      begin
        SystemFieldsMigrator.load_from_yaml(temp_file.path)

        fields = SystemFieldsMigrator.fields
        fields.find { |f| f.name == "field_uniqueless" }.not_nil!.uniqueness.should eq(FieldUniqueness::UNIQUELESS)
        fields.find { |f| f.name == "field_always" }.not_nil!.uniqueness.should eq(FieldUniqueness::UNIQUE_ALWAYS)
        fields.find { |f| f.name == "field_fill" }.not_nil!.uniqueness.should eq(FieldUniqueness::UNIQUE_FILL)
      ensure
        temp_file.delete if temp_file
      end
    end

    it "handles fields without caption" do
      yaml_content = <<-YAML
      ---
      CANDIDATE:
        test_no_caption__str:
          nullable: false
      YAML

      temp_file = File.tempfile("system_fields_no_caption", ".yml") do |file|
        file.print(yaml_content)
      end

      begin
        SystemFieldsMigrator.load_from_yaml(temp_file.path)

        field = SystemFieldsMigrator.fields.first
        field.localized_name.should be_nil
      ensure
        temp_file.delete if temp_file
      end
    end
  end

  describe "#migrate! with YAML" do
    it "automatically loads from default YAML file if it exists" do
      SystemFieldsMigrator.clear!

      result = SystemFieldsMigrator.migrate!

      fields = SystemFieldsMigrator.fields
      fields.should_not be_empty

      candidate_fields = fields.select { |f| f.resource_type == FieldResourceType::CANDIDATE }
      candidate_fields.should_not be_empty

      first_name = candidate_fields.find { |f| f.name == "first_name" }
      first_name.should_not be_nil
    end
  end

  context "with integration testing" do
    note_rt = 101
    student_rt = 102
    gov_rt = 103

    it "creates fields for multiple dummy resources" do
      SystemFieldsMigrator.add_string_field!("dummy_title", to: note_rt, nullable: false)
      SystemFieldsMigrator.add_string_field!("dummy_body", to: note_rt)

      SystemFieldsMigrator.add_int_field!("dummy_grade", to: student_rt)
      SystemFieldsMigrator.add_string_field!("dummy_school", to: student_rt)

      SystemFieldsMigrator.add_boolean_field!("dummy_is_elected", to: gov_rt, nullable: false)

      result = SystemFieldsMigrator.migrate!
      result[:created].should eq(5)

      notes = FieldDefinition.filter(resource_type: note_rt, is_system_field: true).to_a
      students = FieldDefinition.filter(resource_type: student_rt, is_system_field: true).to_a
      officials = FieldDefinition.filter(resource_type: gov_rt, is_system_field: true).to_a

      notes.size.should eq(2)
      students.size.should eq(2)
      officials.size.should eq(1)

      notes.map(&.name).compact.sort.should eq(["dummy_body", "dummy_title"])
      students.map(&.name).compact.sort.should eq(["dummy_grade", "dummy_school"])
      officials.map(&.name).compact.sort.should eq(["dummy_is_elected"])

      notes.find(&.name.==("dummy_title")).not_nil!.nullable.should be_false
      officials.first.not_nil!.data_type_enum.should eq(FieldDataType::DTYPE_BOOLEAN)
    end

    it "keeps same-named fields isolated per resource type" do
      SystemFieldsMigrator.add_string_field!("dummy_label", to: note_rt)
      SystemFieldsMigrator.add_string_field!("dummy_label", to: student_rt)
      SystemFieldsMigrator.migrate!

      note_label = FieldDefinition.filter(resource_type: note_rt, name: "dummy_label").first?
      student_label = FieldDefinition.filter(resource_type: student_rt, name: "dummy_label").first?

      note_label.should_not be_nil
      student_label.should_not be_nil
      note_label.not_nil!.id.should_not eq(student_label.not_nil!.id)
    end

    it "doesn't create duplicates when run multiple times" do
      SystemFieldsMigrator.add_string_field!("dummy_name", to: note_rt)
      SystemFieldsMigrator.migrate!

      initial_fields = FieldDefinition.filter(is_system_field: true, name__startswith: "dummy_").to_a
      initial_ids = initial_fields.map(&.id).compact.sort

      SystemFieldsMigrator.migrate!

      final_fields = FieldDefinition.filter(is_system_field: true, name__startswith: "dummy_").to_a
      final_ids = final_fields.map(&.id).compact.sort
      final_ids.should eq(initial_ids)
    end

    it "updates field properties without changing id or name" do
      SystemFieldsMigrator.add_string_field!("dummy_prop", to: note_rt, nullable: true)
      SystemFieldsMigrator.migrate!

      field = FieldDefinition.filter(resource_type: note_rt, name: "dummy_prop").first.not_nil!
      original_id = field.id
      original_nullable = field.nullable

      SystemFieldsMigrator.clear!
      SystemFieldsMigrator.add_string_field!("dummy_prop", to: note_rt, nullable: false)
      SystemFieldsMigrator.migrate!

      field.reload
      field.id.should eq(original_id)
      field.name.should eq("dummy_prop")
      field.nullable.should eq(false)
      field.nullable.should_not eq(original_nullable)
    end
  end

  context "with data type migrations" do
    before_each do
      SystemFieldsMigrator.clear!
      SystemFieldsMigrator.allow_unsafe_migrations = false
      FieldDefinition.all.delete
      FieldValue.all.delete
    end

    after_each do
      SystemFieldsMigrator.allow_unsafe_migrations = false
    end

    context "when safe transitions" do
      it "migrates INT to FLOAT" do
        SystemFieldsMigrator.add_int_field!("age", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("age", FieldResourceType::CANDIDATE).not_nil!

        fv = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, integer_value: 25_i64)
        fv.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.add_float_field!("age", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field.reload
        field.data_type_enum.should eq(FieldDataType::DTYPE_FLOAT)

        fv.reload
        fv.float_value.should eq(25.0)
        fv.integer_value.should be_nil
      end

      it "migrates INT to STRING" do
        SystemFieldsMigrator.add_int_field!("count", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("count", FieldResourceType::CANDIDATE).not_nil!
        fv = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, integer_value: 42_i64)
        fv.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.add_string_field!("count", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field.reload
        field.data_type_enum.should eq(FieldDataType::DTYPE_STRING)

        fv.reload
        fv.string_value.should eq("42")
        fv.integer_value.should be_nil
      end

      it "migrates FLOAT to STRING" do
        SystemFieldsMigrator.add_float_field!("score", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("score", FieldResourceType::CANDIDATE).not_nil!
        fv = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, float_value: 3.14)
        fv.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.add_string_field!("score", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field.reload
        fv.reload
        fv.string_value.should eq("3.14")
        fv.float_value.should be_nil
      end

      it "migrates BOOLEAN to STRING" do
        SystemFieldsMigrator.add_boolean_field!("active", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("active", FieldResourceType::CANDIDATE).not_nil!
        fv = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, boolean_value: true)
        fv.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.add_string_field!("active", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field.reload
        fv.reload
        fv.string_value.should eq("true")
        fv.boolean_value.should be_nil
      end

      it "migrates DATE to DATETIME" do
        SystemFieldsMigrator.add_date_field!("birth_date", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("birth_date", FieldResourceType::CANDIDATE).not_nil!
        date_value = Time.utc(1990, 1, 15)
        fv = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, date_value: date_value)
        fv.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.add_datetime_field!("birth_date", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field.reload
        field.data_type_enum.should eq(FieldDataType::DTYPE_DATETIME)

        fv.reload
        fv.datetime_value.should eq(date_value)
        fv.date_value.should be_nil
      end
    end

    context "when unsafe transitions" do
      it "blocks STRING to INT without flag" do
        SystemFieldsMigrator.add_string_field!("value", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.add_int_field!("value", to: FieldResourceType::CANDIDATE)

        expect_raises(SystemFieldsMigrator::UnsafeDataTypeMigration, /Cannot migrate.*without --allow-unsafe flag/) do
          SystemFieldsMigrator.migrate!
        end
      end

      it "allows STRING to INT with unsafe flag" do
        SystemFieldsMigrator.add_string_field!("value", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("value", FieldResourceType::CANDIDATE).not_nil!
        fv = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, string_value: "123")
        fv.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.allow_unsafe_migrations = true
        SystemFieldsMigrator.add_int_field!("value", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field.reload
        fv.reload
        fv.integer_value.should eq(123_i64)
        fv.string_value.should be_nil
      end
    end

    context "when conversion failures" do
      it "raises error for invalid string to int conversion" do
        SystemFieldsMigrator.add_string_field!("value", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("value", FieldResourceType::CANDIDATE).not_nil!
        fv = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, string_value: "invalid")
        fv.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.allow_unsafe_migrations = true
        SystemFieldsMigrator.add_int_field!("value", to: FieldResourceType::CANDIDATE)

        expect_raises(SystemFieldsMigrator::DataTypeConversionError, /Failed to convert value/) do
          SystemFieldsMigrator.migrate!
        end
      end
    end

    describe SystemFieldsMigrator::DataTypeConversionError do
      it "rolls back all changes on conversion error" do
        SystemFieldsMigrator.add_string_field!("value", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("value", FieldResourceType::CANDIDATE).not_nil!

        fv1 = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, string_value: "123")
        fv1.save!
        fv2 = FieldValue.new(field: field, resource_id: 2_i64, resource_type: FieldResourceType::CANDIDATE, string_value: "invalid")
        fv2.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.allow_unsafe_migrations = true
        SystemFieldsMigrator.add_int_field!("value", to: FieldResourceType::CANDIDATE)

        expect_raises(SystemFieldsMigrator::DataTypeConversionError) do
          SystemFieldsMigrator.migrate!
        end

        field.reload
        field.data_type_enum.should eq(FieldDataType::DTYPE_STRING)

        fv1.reload
        fv1.string_value.should eq("123")
        fv1.integer_value.should be_nil

        fv2.reload
        fv2.string_value.should eq("invalid")
        fv2.integer_value.should be_nil
      end
    end

    context "when migrating" do
      context "when handling nil" do
        it "preserves nil values during migration" do
          SystemFieldsMigrator.add_int_field!("value", to: FieldResourceType::CANDIDATE)
          SystemFieldsMigrator.migrate!

          field = FieldDefinition.find_by_name_and_resource_type("value", FieldResourceType::CANDIDATE).not_nil!
          fv = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE)
          fv.save!

          SystemFieldsMigrator.clear!
          SystemFieldsMigrator.add_string_field!("value", to: FieldResourceType::CANDIDATE)
          SystemFieldsMigrator.migrate!

          fv.reload
          fv.string_value.should be_nil
          fv.integer_value.should be_nil
        end
      end
    end

    context "when multiple values" do
      it "migrates all field values for a field" do
        SystemFieldsMigrator.add_int_field!("value", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        field = FieldDefinition.find_by_name_and_resource_type("value", FieldResourceType::CANDIDATE).not_nil!

        fv1 = FieldValue.new(field: field, resource_id: 1_i64, resource_type: FieldResourceType::CANDIDATE, integer_value: 10_i64)
        fv1.save!
        fv2 = FieldValue.new(field: field, resource_id: 2_i64, resource_type: FieldResourceType::CANDIDATE, integer_value: 20_i64)
        fv2.save!
        fv3 = FieldValue.new(field: field, resource_id: 3_i64, resource_type: FieldResourceType::CANDIDATE, integer_value: 30_i64)
        fv3.save!

        SystemFieldsMigrator.clear!
        SystemFieldsMigrator.add_string_field!("value", to: FieldResourceType::CANDIDATE)
        SystemFieldsMigrator.migrate!

        fv1.reload
        fv2.reload
        fv3.reload

        fv1.string_value.should eq("10")
        fv2.string_value.should eq("20")
        fv3.string_value.should eq("30")
      end
    end
  end
end
