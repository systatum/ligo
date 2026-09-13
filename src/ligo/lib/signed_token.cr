require "openssl/hmac"

# Creates and verifies lightweight HMAC-signed nonce tokens used for
# stateless integrity checks, e.g. an OAuth flow's state parameter.
module SignedToken
  def self.generate : String
    nonce = Random::Secure.hex(16)
    sig = OpenSSL::HMAC.hexdigest(:sha256, Marten.settings.secret_key, nonce)
    "#{nonce}.#{sig}"
  end

  def self.valid?(token : String) : Bool
    parts = token.split('.', 2)
    return false unless parts.size == 2
    nonce, provided_sig = parts[0], parts[1]
    expected_sig = OpenSSL::HMAC.hexdigest(:sha256, Marten.settings.secret_key, nonce)
    provided_sig == expected_sig
  end
end
