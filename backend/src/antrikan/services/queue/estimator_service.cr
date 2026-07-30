module Antrikan
  record Queue::ChannelEstimation, channel : Channel, items_ahead : Int32

  # For each channel the queue currently has active (not yet done) items in,
  # counts how many other active items in that same channel arrived first -
  # i.e. how many are ahead of this queue in that channel's line.
  class Queue::EstimatorService < BaseService(Array(Queue::ChannelEstimation))
    def initialize(@queue : Queue)
    end

    def run : ServiceResult(Array(ChannelEstimation))
      own_active_items = QueuedItem.filter(queue_id: @queue.id!, status__lt: QueueStatus::DONE.value).to_a
      by_channel = own_active_items.group_by(&.channel_id)

      estimations = by_channel.map do |channel_id, items|
        reference_time = items.map(&.created_at!).min
        items_ahead = QueuedItem.filter(
          channel_id: channel_id,
          status__lt: QueueStatus::DONE.value,
          created_at__lt: reference_time
        ).count

        ChannelEstimation.new(channel: items.first.channel!, items_ahead: items_ahead.to_i32)
      end

      success(estimations)
    end
  end
end
