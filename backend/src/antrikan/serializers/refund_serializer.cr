module Antrikan
  class RefundSerializer < ModelSerializer
    def self.serialize(record, viewer_is_staff : Bool = false)
      new(record, viewer_is_staff).serialize_to_json
    end

    def self.soft_serialize(record, viewer_is_staff : Bool = false)
      new(record, viewer_is_staff).soft_serialize
    end

    def initialize(record, @viewer_is_staff : Bool = false)
      super(record)
    end

    protected def fields
      record = @record.as(Refund)

      {
        id:              record.id.to_s,
        payment_id:      record.payment!.hashed_id,
        amount:          record.amount,
        reason:          record.reason,
        forceful:        record.forceful,
        status:          RefundStatus.from_value(record.status!).to_s,
        review_note:     @viewer_is_staff ? record.review_note : nil,
        images:          fetch_uploaded_files(record.image_ids.try(&.ids)),
        requested_by_id: record.requested_by.try(&.hashed_id),
        reviewed_by_id:  record.reviewed_by.try(&.hashed_id),
        reviewed_at:     record.reviewed_at,
      }
    end
  end
end
