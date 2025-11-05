# Data types supported for a FieldDefinition's value. FieldValue stores typed columns
# (string_value, integer_value, float_value, date_value, date_time_value,
# boolean_value) and this enum maps a FieldDefinition to which typed column should be
# used.
enum FieldDataType
  DTYPE_STRING
  DTYPE_INT
  DTYPE_FLOAT
  DTYPE_DATE
  DTYPE_TIME
  DTYPE_DATETIME
  DTYPE_BOOLEAN
end
