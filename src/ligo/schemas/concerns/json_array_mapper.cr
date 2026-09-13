# Marten stores a JSON array submitted in a request body as a single
# `JSON::Any` entry in `Params::Data`. Array-typed schema fields
# (`field :x, :array, of: :json, ...`) expect each element as its own
# individual value instead, so this flattens a given key when its value is a
# JSON array payload.
#
# Concrete example: a schema declaring
# `field :carousel_images, :array, of: :json, serializable: CarouselImagePayload`.
# A request body like:
#
#   { "carousel_images": [{"keep_id": "abc"}, {"base64_bytes": "...", "mimetype": "image/png"}] }
#
# arrives in `data["carousel_images"]` as ONE `JSON::Any` wrapping the whole
# array. `JsonArrayMapper.map(data, "carousel_images")` rewrites that into TWO
# separate `Params::Data::Value` entries under the same key - one per array
# element - which is what the `:array` schema field needs to deserialize each
# entry (each `{keep_id: ...}` or upload payload)
module JsonArrayMapper
  def self.map(data : Marten::HTTP::Params::Data, key : String) : Marten::HTTP::Params::Data
    value = data[key]?
    json_value = value.as?(JSON::Any)
    return data if json_value.nil?
    return data unless json_value.raw.as?(Array)

    mapped_params = Marten::HTTP::Params::Data::RawHash.new
    data.each do |k, v|
      if k == key
        mapped_entries = [] of Marten::HTTP::Params::Data::Value
        json_value.as_a.each { |entry| mapped_entries << entry }
        mapped_params[k] = mapped_entries
      else
        mapped_params[k] = v
      end
    end

    Marten::HTTP::Params::Data.new(mapped_params)
  end
end
