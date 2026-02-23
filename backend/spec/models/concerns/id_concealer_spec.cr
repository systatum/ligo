require "../../spec_helper"

describe IdConcealer do
  describe ".encode" do
    it "obfuscates an integral ID" do
      # Encoded values should be non-empty strings of expected length
      IdConcealer.encode(0).size.should be >= 12
      IdConcealer.encode(1).size.should be >= 12

      # Different IDs should produce different hashes
      IdConcealer.encode(0).should_not eq IdConcealer.encode(1)
      IdConcealer.encode(1).should_not eq IdConcealer.encode(2)
      IdConcealer.encode(10).should_not eq IdConcealer.encode(11)
    end

    it "is extremely sensitive to any change in the ID (avalanche effect)" do
      # Sequential IDs should produce vastly different encoded strings
      pairs = [{0, 1}, {1, 2}, {10, 11}, {99, 100}, {999, 1000}]
      pairs.each do |a, b|
        encoded_a = IdConcealer.encode(a)
        encoded_b = IdConcealer.encode(b)

        # The encoded strings must differ
        encoded_a.should_not eq encoded_b

        # Count differing characters at each position to show high divergence
        min_len = Math.min(encoded_a.size, encoded_b.size)
        differing_chars = (0...min_len).count { |i| encoded_a[i] != encoded_b[i] }

        # At least half of the characters should differ (avalanche property)
        differing_chars.should be >= (min_len // 2)
      end
    end

    it "produces consistent encoding for same ID" do
      IdConcealer.encode(42).should eq IdConcealer.encode(42)
    end
  end

  describe ".decode" do
    it "reveals an integer ID from the hash form" do
      # Round-trip: encode then decode should return original ID
      [0, 1, 2, 3, 4, 10, 11, 12, 13, 14, 100, 999].each do |id|
        encoded = IdConcealer.encode(id)
        IdConcealer.decode(encoded).should eq id
      end
    end

    it "returns nil for invalid hash" do
      IdConcealer.decode("INVALID").should be_nil
      IdConcealer.decode("").should be_nil
    end
  end
end
