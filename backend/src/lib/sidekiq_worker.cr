# Exposes the performer captured on the running Fiber as `current_user`
# inside job classes, mirroring `CurrentUserDetector#current_user` for
# handlers. Nil unless `PerformerContextRestorer` restored it from an
# enqueuing request, or the job set `Current.set_performer_id` itself.
module Sidekiq::Worker
  protected def current_user : Auth::User?
    Current.user
  end
end
