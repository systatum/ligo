# When included to a model, we add boilerplate code for handling
# int-to-enum conversions or vice versa to any database-backed
# raw integer "enums"
module FieldEnumCoercer
  private macro field_enum_coercer(field_name, enum_type)
    {% map_const = "#{enum_type.stringify.upcase.id}_MAP".id %}
    {{ map_const }} = {{ enum_type }}.values.to_h { |v| {v.to_s.upcase, v.value.to_i64} }

    def coerce_{{ field_name.id }}!
      val = @{{ field_name.id }}
      return if val.nil?

      case val
      when Int64, Int32
        return
      when String
        s = val.as(String)

        if (ival = s.to_i64?)
          @{{ field_name.id }} = ival
          return
        end

        upper = s.upcase
        if {{ map_const }}.has_key?(upper)
          @{{ field_name.id }} = {{ map_const }}[upper]
          return
        end

        raise ArgumentError.new("Unknown {{ field_name.id }} string: '#{s}'. Valid types: #{ {{ map_const }}.keys.join(", ") }")
      else
        raise TypeCastError.new("{{ field_name.id }} must be Int64, Int32, or String, got: #{val.class}")
      end
    end

    private def {{ field_name.id }}! : Int64
      value = @{{ field_name.id }}
      case value
      when Int64
        value
      when Int32
        value.to_i64
      when String
        s = value.as(String)
        if (ival = s.to_i64?)
          ival
        elsif {{ map_const }}.has_key?(s.upcase)
          {{ map_const }}[s.upcase]
        else
          raise ArgumentError.new("Invalid {{ field_name.id }} string: '#{s}'. Must be a valid integer or one of: #{ {{ map_const }}.keys.join(", ") }")
        end
      else
        raise TypeCastError.new("{{ field_name.id }} must be Int64, Int32, or String, got: #{value.class}")
      end
    end

    def {{ field_name.id }}_enum : {{ enum_type }}
      value = {{ field_name.id }}!
      unless value >= Int32::MIN && value <= Int32::MAX
        raise ArgumentError.new("{{ field_name.id }} value #{value} is outside Int32 range")
      end

      val_i32 = value.to_i32
      {{ enum_type }}.from_value?(val_i32) ||
        raise ArgumentError.new("Invalid {{ field_name.id }} value: #{val_i32}. Valid values: #{ {{ enum_type }}.values.map(&.value).join(", ") }")
    end

    def {{ field_name.id }}_enum=(value : {{ enum_type }})
      self.{{ field_name.id }} = value.value.to_i64
    end

    def {{ field_name.id }}=(value : {{ enum_type }})
      @{{ field_name.id }} = value.value.to_i64
    end
  end
end
