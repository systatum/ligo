module Antrikan::QueuedTracker
  macro included
    include StateMachineTracker

    field :attended_at, :date_time, null: true, blank: true
    field :packed_at, :date_time, null: true, blank: true
    field :ready_at, :date_time, null: true, blank: true
    field :dispatched_at, :date_time, null: true, blank: true
    field :delivered_at, :date_time, null: true, blank: true       # when marked as done
    field :created_at, :date_time, null: false, auto_now_add: true # when entered for the first time, aka queued

    state_machine :status, Antrikan::QueueStatus, :QUEUED, {
      queued:      {enter: -> { self.created_at = Time.utc }},
      attended:    {enter: -> { self.attended_at = Time.utc; self.ready_at = nil }},
      packed:      {enter: -> { self.packed_at = Time.utc }},
      ready:       {enter: -> { self.ready_at = Time.utc }},
      dispatching: {enter: -> { self.dispatched_at = Time.utc }},
      done:        {enter: -> { self.delivered_at = Time.utc }},
      canceled:    {enter: -> { self.deleted_at = Time.utc }},
    }, {
      # "public" events can skip one or more state but only
      # linearly in forward direction
      attended:    {from: :queued, to: :attended},
      packed:      {from: [:queued, :attended], to: :packed},
      ready:       {from: [:queued, :attended, :packed], to: :ready},
      dispatching: {from: [:queued, :attended, :packed, :ready], to: :dispatching},
      done:        {from: [:queued, :attended, :packed, :ready, :dispatching], to: :done},
      canceled:    {from: [:queued, :attended, :packed, :ready, :dispatching, :done], to: :canceled},

      # "internal" events, can go backwards
      unready: {from: :ready, to: :attended},
    }
  end
end
