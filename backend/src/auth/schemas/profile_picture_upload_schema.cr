module Auth
  class ProfilePictureUploadSchema < BaseSchema
    field :profile_picture, :image, required: true
  end
end
