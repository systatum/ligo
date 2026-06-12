module SchemaDefiner
  # Defines arbitrary number of schema variants with one shared fields shape.
  # Each variant can then specifically define which fields are "required" or "disallowed".
  # See example in src/antrikan/schemas/channel_schema and
  # src/antrikan/schemas/queue_schema.
  macro with_fields(fields, variants)
    {% for variant, variant_config in variants %}
      class {{variant.id}} < BaseSchema
        {% required_fields = nil %}
        {% disallowed_fields = nil %}
        {% if variant_config.is_a?(NamedTupleLiteral) %}
          {% required_fields = variant_config[:required] %}
          {% disallowed_fields = variant_config[:disallowed] %}
        {% end %}

        {% if disallowed_fields && !disallowed_fields.empty? %}
          validate :validate_disallowed_fields

          private def validate_disallowed_fields
            {% for disallowed_field in disallowed_fields %}
              if data.has_key?({{ disallowed_field.stringify }}) || data.has_key?(:{{ disallowed_field.id }})
                errors.add(:{{ disallowed_field.id }}, "This field is not allowed")
              end
            {% end %}
          end
        {% end %}
        
        {% for field_name, config in fields %}
          {% type = config[:type] %}
          
          {% kwargs = [] of String %}
          {% for k, v in config %}
            # filter out :type AND any pre-existing :required from the base fields
            {% if k.id != "type".id && k.id != "required".id %}
              {% kwargs << "#{k.id}: #{v.id}".id %}
            {% end %}
          {% end %}

          {% is_req = false %}
          {% if required_fields %}
            {% for req in required_fields %}
              {% if req.id == field_name.id %}
                {% is_req = true %}
              {% end %}
            {% end %}
          {% end %}

          {% is_disallowed = false %}
          {% if disallowed_fields %}
            {% for disallowed in disallowed_fields %}
              {% if disallowed.id == field_name.id %}
                {% is_disallowed = true %}
              {% end %}
            {% end %}
          {% end %}
          
          {% kwargs << "required: #{is_req && !is_disallowed}".id %}

          field :{{field_name.id}}, :{{type.id}}, {{ kwargs.join(", ").id }}
        {% end %}
      end
    {% end %}
  end
end
