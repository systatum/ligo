module SlugGenerator
  macro included
    after_initialize :generate_slug
  end

  private def generate_slug
    return unless new_record?
    self.slug = Nanoid.generate(
      size: 6,
      alphabet: "23456789ABCDEFHJKLMNPQRTUVWXY",
      secure: true
    )
  end
end
