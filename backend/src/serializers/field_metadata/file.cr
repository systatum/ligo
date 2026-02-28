module FieldMetadata
  class File < Base
    MIN_FILE_SIZE_MB =    0.0
    MAX_FILE_SIZE_MB = 1024.0

    property many : Bool = false
    property max_mb : Float64 = 3.0
    property ok_mimes : String = "*"

    def initialize(@many : Bool = false, @max_mb : Float64 = 3.0, @ok_mimes : String = "*")
      @type = "file"
    end

    def after_initialize
      if max_mb <= MIN_FILE_SIZE_MB || max_mb > MAX_FILE_SIZE_MB
        raise ArgumentError.new("max_mb must be positive and reasonable")
      end

      ok_mimes_stripped = ok_mimes.strip
      if ok_mimes_stripped.empty?
        ok_mimes = "*"
      elsif ok_mimes_stripped == "*"
        ok_mimes = "*"
      else
        parts = ok_mimes_stripped.split(",").map { |p| p.to_s.strip }.select { |p| !p.empty? }
        if parts.empty?
          raise ArgumentError.new("ok_mimes must contain at least one mime type")
        end
        if parts.any? { |p| !p.includes?("/") }
          raise ArgumentError.new("invalid mime type in ok_mimes")
        end
        ok_mimes = parts.uniq.join(",")
      end
    end

    def ==(other : File) : Bool
      many == other.many &&
        max_mb == other.max_mb &&
        ok_mimes == other.ok_mimes
    end
  end
end
