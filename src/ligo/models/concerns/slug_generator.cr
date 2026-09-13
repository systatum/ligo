module SlugGenerator
  # What characters can be used to generate the Slug.
  # Characters chosen to avoid visual ambiguity
  CHARACTER_SET = "23456789ABCDEFHJKLMNPQRTUVWXY"

  # Generates a random slug/code string
  def self.generate(size : Int32 = 6, alphabet : String = CHARACTER_SET) : String
    Nanoid.generate(
      size: size,
      alphabet: alphabet,
      secure: true
    )
  end

  private def generate_slug
    return unless new_record?

    slug_size = 6 # default is 6 in length
    self.class.fields.each do |field|
      if field.id == "slug"
        field = field.as(Marten::DB::Field::String)
        slug_size = field.max_size
      end
    end

    self.slug = SlugGenerator.generate(slug_size)
  end

  macro included
    after_initialize :generate_slug

    # find record by the slug field
    def self.filter_by_slug(slug : String, unscoped : Bool = false)
      if unscoped
        self.unscoped.filter(slug: slug)
      else
        filter(slug: slug)
      end
    end

    def self.get_by_slug!(slug : String)
      get!(slug: slug)
    end
  end
end
