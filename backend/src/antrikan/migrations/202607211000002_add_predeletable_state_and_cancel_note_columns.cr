class Migration::Antrikan::V202607211000002 < Marten::Migration
  depends_on :antrikan, "202607211000001_renumber_queue_status_values"

  def plan
    # 20 = Antrikan::QueueStatus::ATTENDED
    add_column :antrikan_channel, :predeletable_state, :int, null: false, default: 20
    add_column :antrikan_queued_item, :cancel_note, :string, max_size: 255, null: true
  end
end
