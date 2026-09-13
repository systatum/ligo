# FieldDefinition/FieldValue's resource_type is a plain int, not a fixed enum,
# so any consuming app can attach custom fields to its own resource types
# without Ligo needing to know about them in advance.
#
# Values 0-99 are reserved for Ligo's own generic resource types. Consuming
# apps should constantize their own resource types starting at 100.
module ResourceType
  USER = 1
end
