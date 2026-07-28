require "../../spec_helper"

def create_authorized_queue_item(
  status : Antrikan::QueueStatus = Antrikan::QueueStatus::QUEUED,
  note : String? = nil,
  predeletable_state : Antrikan::QueueStatus? = nil,
)
  organization = create_organization
  owner = create_user(organization: organization)
  space = create_space(manager: owner)
  channel = create_channel(space: space, predeletable_state: predeletable_state)
  queue = create_queue(space: space, queuer: create_queuer(space: space), note: note)
  queued_item = create_queued_item(queue: queue, item: create_item(channel: channel), note: note, status: status)
  user = create_user(organization: organization)

  {
    organization: organization,
    space:        space,
    channel:      channel,
    queue:        queue,
    queued_item:  queued_item,
    user:         user,
  }
end
