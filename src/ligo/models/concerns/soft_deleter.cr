# When included to a model, we will add a soft_delete method
# into that model. Invoking that will only set a deleted_at
# attribute, of which existence indicates that the record
# should no longer be visible
module SoftDeleter
  macro included
    field :deleted_at, :date_time, null: true, blank: true, index: true

    default_scope { filter(deleted_at: nil) }
  end

  def soft_delete
    self.deleted_at = Time.utc
    save
  end

  def soft_delete!
    self.deleted_at = Time.utc
    save!
  end
end
