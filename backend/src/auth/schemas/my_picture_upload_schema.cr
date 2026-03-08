module Auth
  class MyPictureUploadSchema < BaseSchema
    field :profile_picture, :image, required: true
  end
end
