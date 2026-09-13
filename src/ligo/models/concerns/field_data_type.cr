# Data types supported for a FieldDefinition's value. FieldValue stores typed columns
# (string_value, integer_value, float_value, date_value, date_time_value,
# boolean_value) and this enum maps a FieldDefinition to which typed column should be
# used. Additional data types (choice, file, locale-aware text, etc.) are represented
# here and may carry extra information in the FieldDefinition.metadata JSON column.
#
# Note: core numeric values are preserved by placing core value types first in a
# stable order. This keeps existing numeric mappings stable in tests and migrations.
enum FieldDataType
  # Core types
  DTYPE_STRING   = 100
  DTYPE_INT      = 101
  DTYPE_FLOAT    = 102
  DTYPE_DATE     = 103
  DTYPE_TIME     = 104
  DTYPE_DATETIME = 105
  DTYPE_BOOLEAN  = 106

  # Extended / higher-level types
  DTYPE_TEXT      = 200
  DTYPE_TEXT_RICH = 201
  DTYPE_YESNO     = 202
  DTYPE_EMAIL     = 203
  DTYPE_PHONE     = 204
  DTYPE_COUNTRY   = 205
  DTYPE_LOCALE    = 206
  DTYPE_COLOR     = 207
  DTYPE_MONEY     = 208

  # Choice types
  DTYPE_CHOICE_DROPDOWN = 300
  DTYPE_CHOICE_RADIO    = 301
  DTYPE_CHOICE_CHECKBOX = 302
  DTYPE_CHOICE_TOGGLE   = 303

  # File types
  DTYPE_FILE_ANY   = 400
  DTYPE_FILE_IMAGE = 401

  def humanized
    case self
    in .dtype_string?          then "string field"
    in .dtype_int?             then "integer field"
    in .dtype_float?           then "float field"
    in .dtype_date?            then "date field"
    in .dtype_time?            then "time field"
    in .dtype_datetime?        then "datetime field"
    in .dtype_boolean?         then "boolean field"
    in .dtype_text?            then "text field"
    in .dtype_text_rich?       then "rich text field"
    in .dtype_yesno?           then "yes/no field"
    in .dtype_email?           then "email field"
    in .dtype_phone?           then "phone field"
    in .dtype_country?         then "country field"
    in .dtype_locale?          then "locale field"
    in .dtype_color?           then "color field"
    in .dtype_money?           then "money field"
    in .dtype_choice_dropdown? then "choice (dropdown) field"
    in .dtype_choice_radio?    then "choice (radio) field"
    in .dtype_choice_checkbox? then "choice (checkbox) field"
    in .dtype_choice_toggle?   then "choice (toggle) field"
    in .dtype_file_any?        then "file field"
    in .dtype_file_image?      then "file (image) field"
    end
  end
end
