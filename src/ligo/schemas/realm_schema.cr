module Ligo
  class RealmSchema < BaseSchema
    field :app_name, :string, max_size: 255
    field :app_id, :string, max_size: 255
    field :app_secret, :string, max_size: 255
    field :ack_semantic, :enum, values: AcknowledgeSemantic
    field :default_role, :int, required: false
    field :max_ack_retry_attempts, :int, required: false
    field :registration_redirection_uri, :string, max_size: 200, required: false
    field :registration_ack_uri, :string, max_size: 200, required: false
  end
end
