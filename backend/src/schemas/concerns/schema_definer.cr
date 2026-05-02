module SchemaDefiner
  # Defines arbitrary number of schema variants with one shared fields shape.
  # Each variant can then specifically define which fields are required.
  # See example in src/antrikan/schemas/channel_schema.
  macro with_fields(fields, variants)
    {% for variant, variant_config in variants %}
      class {{variant.id}} < BaseSchema
        {% required_fields = nil %}
        {% if variant_config.is_a?(NamedTupleLiteral) %}
          {% required_fields = variant_config[:required] %}
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
          
          {% kwargs << "required: #{is_req}".id %}

          field :{{field_name.id}}, :{{type.id}}, {{ kwargs.join(", ").id }}
        {% end %}
      end
    {% end %}
  end
end
