class Migration::Antrikan::V202607231200004 < Marten::Migration
  depends_on :antrikan, "202607231200003_generalize_antrikan_operating_hour_owner"

  def plan
    add_column :antrikan_channel, :enforce_operating_hours, :bool, null: false, default: false
  end
end
