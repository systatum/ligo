# Marten stores a JSON array submitted in a request body as a single
# `JSON::Any` entry in `Params::Data`. Array-typed schema fields
# (`field :x, :array, of: :json, ...`) expect each element as its own
# individual value instead, so this flattens a given key when its value is a
# JSON array payload - the same normalization `Space::MemberRegisterService`
# already does inline for `SpaceJoinSchema#users`.
module JsonArrayFieldNormalizer
  def self.normalize(data : Marten::HTTP::Params::Data, key : String) : Marten::HTTP::Params::Data
    value = data[key]?
    json_value = value.as?(JSON::Any)
    return data if json_value.nil?
    return data unless json_value.raw.as?(Array)

    normalized_params = Marten::HTTP::Params::Data::RawHash.new
    data.each do |k, v|
      if k == key
        normalized_entries = [] of Marten::HTTP::Params::Data::Value
        json_value.as_a.each { |entry| normalized_entries << entry }
        normalized_params[k] = normalized_entries
      else
        normalized_params[k] = v
      end
    end

    Marten::HTTP::Params::Data.new(normalized_params)
  end
end
