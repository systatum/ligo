module Antrikan
  alias StateTimelineEntry = NamedTuple(
    state: String,
    timestamp: String,
    time_taken_seconds: Int64)

  class QueuedItem::HistoryRetrieverService < BaseService(Array(StateTimelineEntry))
    STATE_ORDER = [
      QueueStatus::QUEUED,
      QueueStatus::ATTENDED,
      QueueStatus::PACKED,
      QueueStatus::READY,
      QueueStatus::DISPATCHING,
      QueueStatus::DONE,
      QueueStatus::CANCELED,
    ]

    def initialize(@queued_item : QueuedItem)
    end

    def run : ServiceResult(Array(StateTimelineEntry))
      states = [] of StateTimelineEntry
      previous_time = nil

      STATE_ORDER.each do |status|
        timestamp = state_timestamp(status)
        next unless timestamp
        t = timestamp.not_nil!
        time_taken = previous_time ? (t - previous_time).total_seconds.to_i64 : 0_i64
        states << {state: status.to_s, timestamp: t.to_rfc3339, time_taken_seconds: time_taken}
        previous_time = t
      end

      success(states)
    end

    private def state_timestamp(status : QueueStatus)
      case status
      when .queued?      then @queued_item.created_at
      when .attended?    then @queued_item.attended_at
      when .packed?      then @queued_item.packed_at
      when .ready?       then @queued_item.ready_at
      when .dispatching? then @queued_item.dispatched_at
      when .done?        then @queued_item.delivered_at
      when .canceled?    then @queued_item.deleted_at
      end
    end
  end
end
