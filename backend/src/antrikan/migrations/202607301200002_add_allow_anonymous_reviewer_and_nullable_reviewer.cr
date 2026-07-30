class Migration::Antrikan::V202607301200002 < Marten::Migration
  depends_on :antrikan, "202607301200001_add_parent_channel_id_to_antrikan_channel_table"

  def plan
    add_column :antrikan_space, :allow_anonymous_reviewer, :bool, null: false, default: false
    change_column :antrikan_space_review, :reviewer_id, :reference, to_table: :auth_user, to_column: :id, null: true
  end
end
