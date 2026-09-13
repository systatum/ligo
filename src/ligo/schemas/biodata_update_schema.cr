module Ligo
  class BiodataUpdateSchema < BaseSchema
    field :first_name, :string, max_size: 255, strip: true, required: false
    field :last_name, :string, max_size: 255, strip: true, required: false
    field :locale, :string, max_size: 7, strip: true, required: false
    field :timezone_offset_seconds, :int, required: false

    validate :validate_locale

    private def validate_locale
      return unless locale?

      unless User::ALLOWED_LOCALES.includes?(locale!)
        errors.add(:locale, "Must be one of: #{User::ALLOWED_LOCALES.join(", ")}")
      end
    end
  end
end
