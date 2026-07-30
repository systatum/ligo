module Antrikan
  class SpaceReview < Marten::Model
    include ChangeTracker
    include SoftDeleter
    include IdConcealer

    field :id, :big_int, primary_key: true, auto: true
    field :rating, :float, null: false
    field :review, :text, null: true, blank: true
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    field :space, :many_to_one, to: Antrikan::Space, related: :reviews
    field :reviewer, :many_to_one, to: Auth::User, related: :space_reviews, null: true, blank: true
    field :channel, :many_to_one, to: Antrikan::Channel, related: :reviews, null: true, blank: true
    field :item, :many_to_one, to: Antrikan::Item, related: :reviews, null: true, blank: true

    db_unique_constraint :idx_space_review_space_reviewer_unique, field_names: [:space, :reviewer]

    validate :validate_rating
    validate :validate_uniqueness
    validate :validate_channel_and_item

    private def validate_rating
      return if rating.nil?

      unless (0.0..10.0).includes?(rating!)
        errors.add(:rating, "Rating must be between 0.0 and 10.0")
      end
    end

    private def validate_uniqueness
      return unless space? && reviewer?

      existing = SpaceReview.filter(space_id: space!.id, reviewer_id: reviewer!.id).to_a
      existing = existing.reject { |r| r.id == id } unless new_record?

      errors.add(:reviewer, "You have already reviewed this space") unless existing.empty?
    end

    private def validate_channel_and_item
      if channel? && item?
        errors.add(:item, "cannot be set together with channel")
        return
      end

      if channel? && channel!.space_id != space_id
        errors.add(:channel, "must belong to the same space as the review")
      end

      if item? && item!.channel!.space_id != space_id
        errors.add(:item, "must belong to the same space as the review")
      end
    end
  end
end
