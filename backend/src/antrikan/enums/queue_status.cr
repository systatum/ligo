module Antrikan
  enum QueueStatus
    CANCELED    = 0
    QUEUED      = 1
    ATTENDED    = 2
    PACKED      = 3
    READY       = 4
    DISPATCHING = 5
    DONE        = 6

    def self.from_event(event_name : Symbol) : QueueStatus
      case event_name
      when :unready then QueueStatus::ATTENDED
      else               QueueStatus.parse(event_name.to_s.upcase)
      end
    end

    def to_state : Symbol
      case self
      when .queued?      then :queued
      when .attended?    then :attended
      when .packed?      then :packed
      when .ready?       then :ready
      when .dispatching? then :dispatching
      when .done?        then :done
      when .canceled?    then :canceled
      else                    :queued
      end
    end
  end
end
