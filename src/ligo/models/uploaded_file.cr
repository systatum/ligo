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
    # Opt-in; nil for a permanent upload (ie profile picture). Set only by the presigned-upload path.
    field :expires_at, :date_time, null: true, blank: true

    def owned_by?(user : Ligo::User) : Bool
      uploaded_by == user
    end

    # Creates a row for a blob whose bytes Ligo never inspects (e.g. presign-uploaded ciphertext),
    # so original_name/content_type are the generic placeholders this flow always uses.
    def self.create_opaque!(
      byte_size : Int64,
      uploaded_by : Ligo::User? = nil,
      expires_at : Time? = nil,
      id : UUID = UUID.random,
    ) : self
      create!(
        id: id,
        original_name: "upload",
        content_type: "application/octet-stream",
        byte_size: byte_size,
        uploaded_by: uploaded_by,
        expires_at: expires_at,
      )
    end
  end
end
