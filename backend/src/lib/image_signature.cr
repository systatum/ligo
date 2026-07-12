# Pure-Crystal, dependency-free replacement for libvips-based image
# validation. Checks magic bytes only (JPEG/PNG/GIF/WebP) - it confirms the
# file starts like a genuine image but, unlike a real decode, won't catch a
# file that's truncated or corrupted past the header.
module ImageSignature
  SIGNATURES = [
    Bytes[0xFF, 0xD8, 0xFF],                               # JPEG
    Bytes[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A], # PNG
    Bytes[0x47, 0x49, 0x46, 0x38, 0x37, 0x61],             # GIF87a
    Bytes[0x47, 0x49, 0x46, 0x38, 0x39, 0x61],             # GIF89a
  ]

  RIFF = "RIFF".to_slice
  WEBP = "WEBP".to_slice

  def self.valid?(io : IO) : Bool
    io.rewind
    header = Bytes.new(12)
    return false unless io.read_fully?(header)

    return true if SIGNATURES.any? { |sig| header[0, sig.size] == sig }

    header[0, 4] == RIFF && header[8, 4] == WEBP
  ensure
    io.rewind
  end
end
