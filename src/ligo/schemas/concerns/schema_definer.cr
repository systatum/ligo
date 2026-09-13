module SchemaDefiner
  # Generates one `BaseSchema` subclass per variant from one shared field set.
  #
  #   BaseSchema.with_fields(
  #     fields: {
  #       rating: {type: :float, min_value: 0.0, max_value: 10.0},
  #       images: {type: :array, of: :json, serializable: CarouselImagePayload},
  #     },
  #     variants: {
  #       ReviewSchema:       {required: [:rating]},
  #       ReviewUpdateSchema: {disallowed: [:reviewer_id]},
  #     },
  #     validations: {
  #       validate_images_size: -> { validate_max_images(:images, images, 4) },
  #     }
  #   )
  #
  # `fields` values must include `type:`; every other key (`strip:`, `max_size:`,
  # `min_value:`/`max_value:`, `values:`, `of:`, `serializable:`, ...) passes
  # through verbatim to the generated `field` call, symbols included.
  #
  # `variants` values are `nil` (nothing required or disallowed) or a NamedTuple
  # with `required: [:field, ...]` and/or `disallowed: [:field, ...]` - a
  # disallowed field present in the request data adds a "not allowed" error.
  #
  # `validations` (optional) maps a method name to a `-> { ... }` proc; its body
  # becomes that method's body, registered via `validate`, on every variant.
  macro with_fields(fields, variants, validations = nil)
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
              {% if v.is_a?(SymbolLiteral) %}
                # v.id would strip the leading colon (e.g. :json -> json), breaking
                # kwargs whose value must stay a symbol, e.g. `of: :json`.
                {% kwargs << "#{k.id}: #{v}".id %}
              {% else %}
                {% kwargs << "#{k.id}: #{v.id}".id %}
              {% end %}
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

        {% if validations %}
          {% for validation_name, validation_proc in validations %}
            validate :{{validation_name.id}}

            private def {{validation_name.id}}
              {{ validation_proc.body }}
            end
          {% end %}
        {% end %}
      end
    {% end %}
  end
end
