class LocalizedName
  include JSON::Serializable
  include YAML::Serializable

  property english : String?
  property indonesian : String?
  property japanese : String?

  def initialize(@english : String? = nil, @indonesian : String? = nil, @japanese : String? = nil)
  end

  def localized(locale : String = "english") : String?
    case locale.downcase
    when "english", "en", "en-US"
      english
    when "indonesian", "id", "id-ID"
      indonesian
    when "japanese", "jp", "ja", "ja-JP"
      japanese
    else
      english || indonesian || japanese
    end
  end

  def fallback : String?
    english.presence || indonesian.presence || japanese.presence
  end

  def to_s(io : IO) : Nil
    fallback.to_s(io)
  end

  def ==(other : LocalizedName) : Bool
    english == other.english &&
      indonesian == other.indonesian &&
      japanese == other.japanese
  end
end
