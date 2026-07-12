# Describes the acknowledgement contract between a sender and receiver.
# Each variant defines how the sender confirms that the receiver has
# processed a notification:
enum AcknowledgeSemantic
  NONE     = 0 # ack'ed automatically
  OPTIONAL = 1 # send callback once, not acked automatically
  MUTUAL   = 2 # send callback until ack'ed
end
