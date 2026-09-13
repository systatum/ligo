module Ligo
  # A durable, queryable attempt log for outbound webhook deliveries,
  # grouped by content_id.
  class WebhookDelivery < Marten::Model
    include SoftDeleter

    field :id, :big_int, primary_key: true, auto: true
    # UUID grouping all attempts for the same event.
    field :content_id, :string, max_size: 200
    # true if the target responded 200/204.
    # false if it timed out, returned non-2xx, or was unreachable.
    field :succeeded, :bool
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true
  end
end
