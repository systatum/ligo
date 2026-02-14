# Specifies which resource a FieldDefinition (attribute) applies to.
# Use this to scope metadata: e.g. USER means the FieldDefinition is for user records,
# CANDIDATE means the FieldDefinition is for candidate records.
enum FieldResourceType
  USER           = 1
  CANDIDATE      = 2
  EMAIL_TEMPLATE = 3
end
