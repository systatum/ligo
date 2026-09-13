module Ligo
  # A Realm is an OAuth Client registration: a trusted third-party app that
  # delegates authentication to this deployment as its Identity Provider
  # (IdP). Each Realm brings its own upstream credentials (e.g. a Facebook
  # App), so the end user sees the correct branding during the OAuth
  # consent flow.
  class Realm < Marten::Model
    include SoftDeleter

    DEFAULT_MAX_ACK_RETRY_ATTEMPTS = 50

    # Unique identifier for the realm (12 chars).
    field :id, :string, max_size: 12, primary_key: true
    # Display name of the third-party application.
    field :app_name, :string, max_size: 255
    # SHA-256 hash of the raw api_secret_key. The raw value
    # is returned once at creation and cannot be retrieved later.
    field :hashed_api_secret_key, :string, max_size: 65
    # SHA-256 hash of the raw api_client_key. Intended for
    # frontend communication (publicly exposable).
    field :hashed_api_client_key, :string, max_size: 65
    # Plain-text secret (15 chars) used for HMAC-SHA256 signing
    # of outbound webhook payloads in the X-Systatum-Signature header.
    field :webhook_secret, :string, max_size: 15
    # Controls registration notification behavior.
    field :ack_semantic, :enum, values: AcknowledgeSemantic
    # Maximum webhook delivery retries (defaults to 50).
    # Applies only when ack_semantic is MUTUAL.
    field :max_ack_retry_attempts, :int, null: true, blank: true, default: DEFAULT_MAX_ACK_RETRY_ATTEMPTS
    # Destination URI for browser redirection after OAuth login.
    # On failure, "?registration_failed=true" is appended.
    field :registration_redirection_uri, :string, max_size: 200, null: true, blank: true
    # Backend endpoint for receiving registration notifications.
    # When ack_semantic is MUTUAL, the target must respond
    # with 200/204 to trigger ack_at.
    field :registration_ack_uri, :string, max_size: 200, null: true, blank: true
    # Upstream OAuth provider's application ID.
    field :app_id, :string, max_size: 255
    # Upstream OAuth provider's application secret.
    field :app_secret, :string, max_size: 255
    # Role assigned to a user who self-registers by founding a brand-new
    # organization under this realm.
    field :default_role, :int, null: false, blank: false, default: Role::OWNER
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true
  end
end
