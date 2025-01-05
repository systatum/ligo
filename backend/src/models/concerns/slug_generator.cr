module SlugGenerator
  macro included
    after_initialize :generate_slug
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

    self.slug = Nanoid.generate(
      size: slug_size,
      alphabet: "23456789ABCDEFHJKLMNPQRTUVWXY",
      secure: true
    )
  end
end
