# Looks up whether a numeric city code belongs to a known city, reading
# reference data from data/countries/<country_code>_<ISO 3166-1 alpha-3>.json
# in the consuming app's own project root. Ligo ships no data files of its
# own; each app supplies its own data/countries directory.
module CountryCityDirectory
  COUNTRIES_DIR = "data/countries"

  @@city_ids_by_country_code = {} of Int32 => Set(Int32)

  def self.valid_city_code?(city_code : Int32 | Int64) : Bool
    code = city_code.to_i32
    country_code = code // 1_000_000
    city_ids_for(country_code).includes?(code)
  end

  private def self.city_ids_for(country_code : Int32) : Set(Int32)
    @@city_ids_by_country_code[country_code] ||= load_city_ids(country_code)
  end

  private def self.load_city_ids(country_code : Int32) : Set(Int32)
    file = Dir.glob("#{COUNTRIES_DIR}/#{country_code}_*.json").first?
    return Set(Int32).new if file.nil?

    data = JSON.parse(File.read(file))
    data["cities"].as_h.keys.map(&.to_i).to_set
  end
end
