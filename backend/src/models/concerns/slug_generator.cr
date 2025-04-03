module SlugGenerator
  # what characters can be used to genereate the Slug
  CHARACTER_SET = "23456789ABCDEFHJKLMNPQRTUVWXY"

  private def generate_slug
    return unless new_record?

    slug_size = 6 # default is 6 in length
    self.class.fields.each do |field|
      if field.id == "slug"
        field = field.as(Marten::DB::Field::String)
        slug_size = field.max_size
      end
    end

    self.slug = Nanoid.generate(
      size: slug_size,
      alphabet: CHARACTER_SET,
      secure: true
    )
  end

  macro included
    after_initialize :generate_slug

    # find record by the hashed ID
    def self.filter_by_slug(slug : String)
      filter(slug: slug)
    end
  end
end
