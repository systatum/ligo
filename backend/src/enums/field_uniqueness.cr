# Rules describing uniqueness constraints for FieldDefinition values across resources.
# - UNIQUELESS: no uniqueness enforced
# - UNIQUE_ALWAYS: value must be unique for this FieldDefinition across the resource type
# - UNIQUE_FILL: uniqueness enforced only when the value is present (non-null)
enum FieldUniqueness
  UNIQUELESS    = 0
  UNIQUE_ALWAYS = 1
  UNIQUE_FILL   = 2
end
