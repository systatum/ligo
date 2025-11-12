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

    def initialize(
      @name : String,
      @resource_type : FieldResourceType,
      @data_type : FieldDataType,
      @localized_name : LocalizedName? = nil,
      @nullable : Bool = true,
      @uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
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
    FieldDataType::DTYPE_INT      => [FieldDataType::DTYPE_FLOAT, FieldDataType::DTYPE_STRING],
    FieldDataType::DTYPE_FLOAT    => [FieldDataType::DTYPE_STRING],
    FieldDataType::DTYPE_DATE     => [FieldDataType::DTYPE_DATETIME, FieldDataType::DTYPE_STRING],
    FieldDataType::DTYPE_TIME     => [FieldDataType::DTYPE_STRING],
    FieldDataType::DTYPE_DATETIME => [FieldDataType::DTYPE_STRING],
    FieldDataType::DTYPE_BOOLEAN  => [FieldDataType::DTYPE_STRING],
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
    old_data_type = field_def.data_type.not_nil!
    return if old_data_type == new_data_type

    field_values = FieldValue.filter(field_id: field_def.id!)

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
    when FieldDataType::DTYPE_STRING
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
  )
    config = FieldDefinitionConfig.new(
      name: name,
      resource_type: resource_type,
      data_type: data_type,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
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
  )
    add_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      data_type: data_type,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
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
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_STRING,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_string_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_string_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_int_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_INT,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_int_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_int_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_float_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_FLOAT,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_float_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_float_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_date_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_DATE,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_date_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_date_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_time_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_TIME,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_time_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_time_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_datetime_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_DATETIME,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_datetime_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_datetime_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_boolean_field!(
    name : String,
    to resource_type : FieldResourceType,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_field!(
      name: name,
      to: resource_type,
      data_type: FieldDataType::DTYPE_BOOLEAN,
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def add_boolean_field!(
    name : String,
    to resource_type_raw : Int32,
    localized_name : LocalizedName? = nil,
    nullable : Bool = true,
    uniqueness : FieldUniqueness = FieldUniqueness::UNIQUELESS,
  )
    add_boolean_field!(
      name: name,
      to: FieldResourceType.new(resource_type_raw),
      localized_name: localized_name,
      nullable: nullable,
      uniqueness: uniqueness
    )
  end

  def migrate!
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

            if existing_field.data_type != config.data_type
              validate_data_type_transition(
                existing_field.data_type.not_nil!,
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
              data_type: config.data_type,
              nullable: config.nullable,
              uniqueness: config.uniqueness,
              is_system_field: true
            )
            field.resource_type_enum = config.resource_type
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
