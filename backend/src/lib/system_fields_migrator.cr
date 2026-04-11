require "yaml"
require "json"

module SystemFieldsMigrator
  extend self

  @@verbose : Bool = false

  def verbose=(value : Bool)
    @@verbose = value
  end

  def verbose?
    @@verbose
  end

  class FieldDefinitionConfig
    property name : String
    property resource_type : FieldResourceType
    property data_type : FieldDataType
    property localized_name : LocalizedName?
    property nullable : Bool
    property uniqueness : FieldUniqueness
    property metadata : FieldMetadata::Base?

    def initialize(
      @name : String,
      @resource_type : FieldResourceType,
      @data_type : FieldDataType,
      @localized_name : LocalizedName? = nil,
      @nullable : Bool = true,
      @uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
      @metadata : FieldMetadata::Base? = nil,
    )
    end
  end

  class DataTypeMigrationError < Exception
  end

  class UnsafeDataTypeMigration < DataTypeMigrationError
  end

  class DataTypeConversionError < DataTypeMigrationError
  end

  @@fields = [] of FieldDefinitionConfig
  @@allow_unsafe_migrations = false

  def allow_unsafe_migrations=(value : Bool)
    @@allow_unsafe_migrations = value
  end

  def allow_unsafe_migrations
    @@allow_unsafe_migrations
  end

  SAFE_TRANSITIONS = {
    FieldDataType::DTYPE_INT      => [FieldDataType::DTYPE_FLOAT, FieldDataType::DTYPE_STRING, FieldDataType::DTYPE_TEXT],
    FieldDataType::DTYPE_FLOAT    => [FieldDataType::DTYPE_STRING, FieldDataType::DTYPE_TEXT],
    FieldDataType::DTYPE_DATE     => [FieldDataType::DTYPE_DATETIME, FieldDataType::DTYPE_STRING, FieldDataType::DTYPE_TEXT],
    FieldDataType::DTYPE_TIME     => [FieldDataType::DTYPE_STRING, FieldDataType::DTYPE_TEXT],
    FieldDataType::DTYPE_DATETIME => [FieldDataType::DTYPE_STRING, FieldDataType::DTYPE_TEXT],
    FieldDataType::DTYPE_BOOLEAN  => [FieldDataType::DTYPE_STRING, FieldDataType::DTYPE_TEXT],
    FieldDataType::DTYPE_STRING   => [FieldDataType::DTYPE_TEXT],
    FieldDataType::DTYPE_TEXT     => [FieldDataType::DTYPE_STRING],
  }

  private def safe_transition?(from : FieldDataType, to : FieldDataType) : Bool
    return true if from == to
    SAFE_TRANSITIONS[from]?.try(&.includes?(to)) || false
  end

  private def validate_data_type_transition(from : FieldDataType, to : FieldDataType, field_name : String)
    return if from == to

    if !safe_transition?(from, to) && !@@allow_unsafe_migrations
      raise UnsafeDataTypeMigration.new(
        "Cannot migrate field '#{field_name}' from #{from} to #{to} without --allow-unsafe flag. " \
        "This transition may cause data loss."
      )
    end
  end

  private def migrate_field_values(field_def : FieldDefinition, new_data_type : FieldDataType)
    old_data_type = field_def.data_type_enum
    return if old_data_type == new_data_type

    field_values = FieldValue.filter(field: field_def)

    field_values.each do |fv|
      begin
        old_value = fv.actual_value
        next if old_value.nil?

        normalized_value =
          case old_value
          when Int32
            old_value.to_i64
          else
            old_value
          end

        new_value = convert_value(normalized_value, old_data_type, new_data_type)

        clear_value_columns(fv)
        set_value_by_type(fv, new_value, new_data_type)
      rescue ex
        raise DataTypeConversionError.new(
          "Failed to convert value for field '#{field_def.name}' " \
          "(FieldValue id: #{fv.id}): #{ex.message}"
        )
      end
    end
  end

  private def convert_value(
    value : String | Int64 | Float64 | Bool | Time,
    from : FieldDataType,
    to : FieldDataType,
  ) : String | Int64 | Float64 | Bool | Time
    case to
    when FieldDataType::DTYPE_STRING, FieldDataType::DTYPE_TEXT
      value.to_s
    when FieldDataType::DTYPE_INT
      case value
      when Int64
        value
      when Float64
        value.to_i64
      when String
        value.to_i64
      when Bool
        value ? 1_i64 : 0_i64
      else
        raise "Cannot convert #{value.class} to Int64"
      end
    when FieldDataType::DTYPE_FLOAT
      case value
      when Float64
        value
      when Int64
        value.to_f64
      when String
        value.to_f64
      else
        raise "Cannot convert #{value.class} to Float64"
      end
    when FieldDataType::DTYPE_BOOLEAN
      case value
      when Bool
        value
      when Int64
        value != 0
      when String
        ["true", "1", "yes", "y", "t"].includes?(value.downcase)
      else
        raise "Cannot convert #{value.class} to Bool"
      end
    when FieldDataType::DTYPE_DATETIME
      case value
      when Time
        value
      when String
        Time.parse_rfc3339(value)
      else
        raise "Cannot convert #{value.class} to Time"
      end
    when FieldDataType::DTYPE_DATE
      case value
      when Time
        value
      when String
        Time.parse(value, "%Y-%m-%d", Time::Location::UTC)
      else
        raise "Cannot convert #{value.class} to Date"
      end
    when FieldDataType::DTYPE_TIME
      case value
      when Time
        value
      when String
        Time.parse(value, "%H:%M:%S", Time::Location::UTC)
      else
        raise "Cannot convert #{value.class} to Time"
      end
    else
      raise "Unsupported target type: #{to}"
    end
  end

  private def clear_value_columns(fv : FieldValue)
    FieldValue.filter(id: fv.id).update(
      string_value: nil,
      text_value: nil,
      integer_value: nil,
      float_value: nil,
      boolean_value: nil,
      datetime_value: nil,
      date_value: nil,
      time_value: nil
    )
  end

  private def set_value_by_type(fv : FieldValue, value : String | Int64 | Float64 | Bool | Time, data_type : FieldDataType)
    case data_type
    when FieldDataType::DTYPE_STRING
      FieldValue.filter(id: fv.id).update(string_value: value.as(String))
    when FieldDataType::DTYPE_TEXT
      FieldValue.filter(id: fv.id).update(text_value: value.as(String))
    when FieldDataType::DTYPE_INT
      FieldValue.filter(id: fv.id).update(integer_value: value.as(Int64))
    when FieldDataType::DTYPE_FLOAT
      FieldValue.filter(id: fv.id).update(float_value: value.as(Float64))
    when FieldDataType::DTYPE_BOOLEAN
      FieldValue.filter(id: fv.id).update(boolean_value: value.as(Bool))
    when FieldDataType::DTYPE_DATETIME
      FieldValue.filter(id: fv.id).update(datetime_value: value.as(Time))
    when FieldDataType::DTYPE_DATE
      FieldValue.filter(id: fv.id).update(date_value: value.as(Time))
    when FieldDataType::DTYPE_TIME
      FieldValue.filter(id: fv.id).update(time_value: value.as(Time))
    end
  end

  def add_field!(
    name : String,
    to resource_type : FieldResourceType,
    data_type : FieldDataType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    config = FieldDefinitionConfig.new(
      name: name,
      resource_type: resource_type,
      data_type: data_type,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
    @@fields << config
  end

  def add_field!(
    name : String,
    to resource_type_raw : Int32,
    data_type : FieldDataType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      data_type: data_type,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  rescue
    raise ArgumentError.new("Invalid FieldResourceType integer: #{resource_type_raw}")
  end

  def add_string_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_STRING,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_string_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_string_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_int_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_INT,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_int_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_int_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_float_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_FLOAT,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_float_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_float_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_date_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_DATE,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_date_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_date_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_time_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_TIME,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_time_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_time_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_datetime_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_DATETIME,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_datetime_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_datetime_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_boolean_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_BOOLEAN,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_boolean_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
    metadata : FieldMetadata::Base? = nil,
  )
    add_boolean_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_choice_dropdown_field!(
    name : String,
    to resource_type : FieldResourceType,
    options : Array,
    default : String? = nil,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    begin
      metadata = FieldMetadata::Choice.from_json({
        "options" => options,
        "default" => default,
      }.to_json)
    rescue ex
      raise ArgumentError.new("Failed to build choice metadata for field '#{name}': #{ex.message}")
    end
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_CHOICE_DROPDOWN,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_choice_radio_field!(
    name : String,
    to resource_type : FieldResourceType,
    options : Array,
    default : String? = nil,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    begin
      metadata = FieldMetadata::Choice.from_json({
        "options" => options,
        "default" => default,
      }.to_json)
    rescue ex
      raise ArgumentError.new("Failed to build choice metadata for field '#{name}': #{ex.message}")
    end
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_CHOICE_RADIO,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_choice_checkbox_field!(
    name : String,
    to resource_type : FieldResourceType,
    options : Array,
    default : String? = nil,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    begin
      metadata = FieldMetadata::Choice.from_json({
        "options" => options,
        "default" => default,
      }.to_json)
    rescue ex
      raise ArgumentError.new("Failed to build choice metadata for field '#{name}': #{ex.message}")
    end
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_CHOICE_CHECKBOX,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_choice_toggle_field!(
    name : String,
    to resource_type : FieldResourceType,
    options : Array,
    default : String? = nil,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    begin
      metadata = FieldMetadata::Choice.from_json({
        "options" => options,
        "default" => default,
      }.to_json)
    rescue ex
      raise ArgumentError.new("Failed to build choice metadata for field '#{name}': #{ex.message}")
    end
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_CHOICE_TOGGLE,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  # Convenience methods for file field types

  def add_file_field!(
    name : String,
    to resource_type : FieldResourceType,
    many : Bool = false,
    max_mb : Float64 = 3,
    ok_mimes : String | Array(String) = "*",
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    begin
      metadata = FieldMetadata::File.from_json({
        "many"     => many,
        "max_mb"   => max_mb,
        "ok_mimes" => ok_mimes,
      }.to_json)
    rescue ex
      raise ArgumentError.new("Failed to build file metadata for field '#{name}': #{ex.message}")
    end
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_FILE_ANY,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def add_image_field!(
    name : String,
    to resource_type : FieldResourceType,
    many : Bool = false,
    max_mb : Float64 = 3,
    ok_mimes : String | Array(String) = ["image/png", "image/jpeg", "image/gif", "image/webp"],
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    begin
      metadata = FieldMetadata::File.from_json({
        "many"     => many,
        "max_mb"   => max_mb,
        "ok_mimes" => ok_mimes,
      }.to_json)
    rescue ex
      raise ArgumentError.new("Failed to build image metadata for field '#{name}': #{ex.message}")
    end
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_FILE_IMAGE,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness,
      metadata: metadata
    )
  end

  def load_from_yaml(yaml_path : String)
    unless File.exists?(yaml_path)
      raise ArgumentError.new("YAML file not found: #{yaml_path}")
    end

    yaml_content = File.read(yaml_path)
    data = YAML.parse(yaml_content)

    data.as_h.each do |resource_type_str, fields|
      resource_type = parse_resource_type(resource_type_str.as_s)

      fields.as_h.each do |field_key, field_config|
        field_name, data_type = parse_field_key(field_key.as_s)

        config = field_config.as_h
        nullable = config["nullable"]?.try(&.as_bool)
        nullable = true if nullable.nil?
        uniqueness = parse_uniqueness(config["uniqueness"]?.try(&.as_s))
        localized_name =
          if caption = config["caption"]?
            parse_localized_name(caption.as_h)
          else
            nil
          end
        metadata =
          if meta_any = config["metadata"]?
            begin
              parse_metadata(meta_any.as_h, data_type)
            rescue ex
              raise ArgumentError.new("Invalid metadata for field '#{field_name}': #{ex.message}")
            end
          else
            nil
          end

        add_field!(
          name: field_name,
          to: resource_type,
          data_type: data_type,
          localized_name: localized_name,
          nullable: nullable,
          uniqueness: uniqueness,
          metadata: metadata
        )
      end
    end
  end

  def migrate!
    if @@fields.empty?
      yaml_path = File.join(File.dirname(__FILE__), "..", "config", "system_fields.yml")
      if File.exists?(yaml_path)
        load_from_yaml(yaml_path)
      end
    end

    created_count = 0
    updated_count = 0
    skipped_count = 0

    Marten::DB::Connection.default.transaction do
      @@fields.each do |config|
        begin
          existing_field = FieldDefinition.find_by_name_and_resource_type(
            config.name,
            config.resource_type
          )

          if existing_field
            needs_update = false

            existing_data_type = existing_field.data_type_enum
            if existing_data_type != config.data_type
              validate_data_type_transition(
                existing_data_type,
                config.data_type,
                config.name
              )

              migrate_field_values(existing_field, config.data_type)

              existing_field.data_type = config.data_type
              needs_update = true
            end

            if existing_field.nullable != config.nullable
              existing_field.nullable = config.nullable
              needs_update = true
            end

            if existing_field.uniqueness != config.uniqueness
              existing_field.uniqueness = config.uniqueness
              needs_update = true
            end

            if config.localized_name
              if !existing_field.localized_name_equal_to?(config.localized_name)
                existing_field.localized_name = config.localized_name
                needs_update = true
              end
            elsif existing_field.localized_name != nil
              existing_field.localized_name = nil
              needs_update = true
            end

            if config.metadata
              if !existing_field.metadata_equal_to?(config.metadata)
                existing_field.metadata = config.metadata
                needs_update = true
              end
            elsif existing_field.metadata != nil
              existing_field.metadata = nil
              needs_update = true
            end

            if !existing_field.is_system_field
              existing_field.is_system_field = true
              needs_update = true
            end

            if needs_update
              existing_field.refresh_original_name!
              existing_field.save!
              updated_count += 1
              log "  ✓ Updated system field: #{config.name} for #{config.resource_type}"
            else
              skipped_count += 1
              log "  - Skipped (no changes): #{config.name} for #{config.resource_type}"
            end
          else
            field = FieldDefinition.new(
              name: config.name,
              nullable: config.nullable,
              uniqueness: config.uniqueness,
              is_system_field: true,
              metadata: config.metadata
            )
            field.resource_type_enum = config.resource_type
            field.data_type_enum = config.data_type
            field.localized_name = config.localized_name
            field.save!
            created_count += 1
            log "  ✓ Created system field: #{config.name} for #{config.resource_type}"
          end
        rescue ex : Exception
          log "  ✗ Error processing field #{config.name} for #{config.resource_type}: #{ex.message}"
          raise ex
        end
      end
    end
    {
      created: created_count,
      updated: updated_count,
      skipped: skipped_count,
      total:   @@fields.size,
    }
  end

  private def parse_resource_type(str : String) : FieldResourceType
    FieldResourceType.parse(str)
  end

  private def parse_field_key(key : String) : Tuple(String, FieldDataType)
    parts = key.split("__")
    raise ArgumentError.new("Invalid field key format: #{key}. Expected format: field_name__type") if parts.size != 2

    field_name = parts[0]
    type_str = parts[1]

    data_type =
      case type_str
      when "string", "str"
        FieldDataType::DTYPE_STRING
      when "text_rich"
        FieldDataType::DTYPE_TEXT_RICH
      when "text"
        FieldDataType::DTYPE_TEXT
      when "int"
        FieldDataType::DTYPE_INT
      when "float"
        FieldDataType::DTYPE_FLOAT
      when "boolean", "bool"
        FieldDataType::DTYPE_BOOLEAN
      when "date"
        FieldDataType::DTYPE_DATE
      when "time"
        FieldDataType::DTYPE_TIME
      when "datetime", "dt"
        FieldDataType::DTYPE_DATETIME
      else
        raise ArgumentError.new("Unknown data type: #{type_str}")
      end

    {field_name, data_type}
  end

  private def parse_uniqueness(str : String?) : FieldUniqueness
    return FieldUniqueness::UNIQUELESS if str.nil?

    case str.upcase
    when "UNIQUELESS"
      FieldUniqueness::UNIQUELESS
    when "UNIQUE_ALWAYS"
      FieldUniqueness::UNIQUE_ALWAYS
    when "UNIQUE_FILL"
      FieldUniqueness::UNIQUE_FILL
    else
      raise ArgumentError.new("Unknown uniqueness: #{str}")
    end
  end

  private def parse_localized_name(caption_hash : Hash(YAML::Any, YAML::Any)) : LocalizedName
    english = caption_hash["en"]?.try(&.as_s)
    indonesian = caption_hash["id"]?.try(&.as_s)
    japanese = caption_hash["ja"]?.try(&.as_s)

    LocalizedName.new(
      english: english,
      indonesian: indonesian,
      japanese: japanese
    )
  end

  private def parse_metadata(metadata_hash : Hash(YAML::Any, YAML::Any), data_type : FieldDataType) : FieldMetadata::Base
    yam_key = YAML.parse("type")
    unless metadata_hash.has_key?(yam_key)
      metadata_hash[yam_key] = YAML.parse(FieldMetadata.to_metadata_type!(data_type))
    end
    FieldMetadata::Base.from_json(metadata_hash.to_json)
  end

  def clear!
    @@fields.clear
  end

  def fields
    @@fields
  end

  private def log(message : String)
    return unless @@verbose
    puts message
  end
end
