# When we must absolutely be sure that a record's slug is unique,
# please use SlugGenerator, which will assign a unique Slug to each
# record. IdConcealer simply hash the ID, and hope that there's no
# hash collison. However, it's written that Hashids, the underlying
# library used for the ID obfuscation, is meant to be used for
# obfuscating IDs, like the one employed by YouTube, so we could
# hope that indeed, there should be no clash. But no further research
# has been made to check such claim.
module IdConcealer
  @@hashids : Hashids = Hashids.new(
    salt: AppSettings.instance.ligo_salt_for_id_concealer,
    min_hash_size: 12,
    alphabet: SlugGenerator::CHARACTER_SET,
  )

  def self.encode(id : Int32 | Int64) : String
    @@hashids.encode([id])
  end

  def self.decode(encoded_id : String) : Int32 | Int64 | Nil
    return nil if encoded_id.empty?

    begin
      decoded_id = @@hashids.decode(encoded_id)
      return nil if decoded_id.empty?
      decoded_id[0]
    rescue
      nil
    end
  end

  # return ID but hashed; the hashed ID is not persisted
  # in the database
  def hashed_id : String
    IdConcealer.encode(id!)
  end

  macro included
    # find record by the hashed ID
    def self.get_by_hashed_id(hashed_id : String)
      get(id: IdConcealer.decode(hashed_id))
    end

    def self.get_by_hashed_id!(hashed_id : String)
      get!(id: IdConcealer.decode(hashed_id))
    end

    def self.filter_by_hashed_id(hashed_id : String, unscoped : Bool = false)
      query = unscoped ? self.unscoped : self.all
      query.filter(id: IdConcealer.decode(hashed_id))
    end

    def self.index_by_hashed_ids(hashed_ids : Set(String))
      decoded_map = hashed_ids.each_with_object({} of Int64 => String) do |hashed_id, map|
        next unless (decoded = IdConcealer.decode(hashed_id))
        map[decoded.to_i64] = hashed_id
      end

      self.filter(id__in: decoded_map.keys).each_with_object({} of String => {{ @type }}) do |record, result|
        next unless (hashed_id = decoded_map[record.id!.to_i64]?)
        result[hashed_id] = record
      end
    end
  end
end
