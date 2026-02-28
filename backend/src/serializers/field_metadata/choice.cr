module FieldMetadata
  class Choice < Base
    class Option
      include JSON::Serializable

      alias CaptionHash = Hash(String, String)
      alias CaptionType = String | CaptionHash

      property id : String
      property caption : CaptionType

      def initialize(@id : String, @caption : CaptionType)
      end

      def after_initialize
        if caption.is_a?(Hash)
          caption_hash = caption.as(CaptionHash)
          raise ArgumentError.new("option caption must include an 'en' locale string") unless caption_hash.has_key?("en")
        end
      end
    end

    property options : Array(Option)
    property default : String?

    def initialize(@options : Array(Option), @default : String? = nil)
      @type = "choice"
    end

    def after_initialize
      ids = options.map { |opt| opt.id }
      raise ArgumentError.new("option ids must be unique") unless ids.size == ids.uniq.size

      if default && !ids.includes?(default)
        raise ArgumentError.new("default '#{default}' not found among provided options")
      end
    end

    def ==(other : Choice) : Bool
      options == other.options &&
        default == other.default
    end
  end
end
