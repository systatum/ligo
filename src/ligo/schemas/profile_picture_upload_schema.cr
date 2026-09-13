module Ligo
  class ProfilePictureUploadSchema < BaseSchema
    field :profile_picture, :file, required: true

    validate :validate_profile_picture_is_image

    private def validate_profile_picture_is_image
      file = profile_picture
      return unless file
      return if ImageSignature.valid?(file.io)

      errors.add(:profile_picture, "is not a valid image")
    end
  end
end
