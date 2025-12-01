class Changelog < Marten::Model
  field :id, :big_int, primary_key: true, auto: true
  field :action_type, :enum, values: ActionType, null: false, blank: false
  field :record_class, :string, max_size: 255, null: false, blank: false
  field :record_id, :big_int, null: false, blank: false
  field :changes, :json, null: true, blank: true
  field :performer_id, :big_int, null: true, blank: true
  field :created_at, :date_time, null: false, auto_now_add: true
  field :updated_at, :date_time, null: false, auto_now: true

  enum ActionType
    CREATE
    UPDATE
    DELETE
  end
end
