module Ligo
  class UploadedFile < Marten::Model
    include SoftDeleter

    field :id, :uuid, primary_key: true
    field :original_name, :string, max_size: 255, null: false, blank: false
    field :content_type, :string, max_size: 127, null: false, blank: false
    field :byte_size, :big_int, null: false, blank: false
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    field :uploaded_by, :many_to_one, to: Ligo::User, related: :uploaded_files, null: true, blank: true

    def owned_by?(user : Ligo::User) : Bool
      uploaded_by == user
    end
  end
end
