# Carries the request's performer id onto jobs it enqueues, and restores it
# on the worker Fiber that executes them - so `Current.user`/`current_user`
# resolve the same way inside a job as they did in the request that queued it.
class PerformerContextPropagator < Sidekiq::Middleware::ClientEntry
  def call(job : Sidekiq::Job, ctx : Sidekiq::Context, &block : -> Bool) : Bool
    if (performer_id = Current.performer_id)
      job.extra_params = job.extra_params.merge({"performer_id" => JSON::Any.new(performer_id)})
    end

    yield
  end
end

class PerformerContextRestorer < Sidekiq::Middleware::ServerEntry
  def call(job : Sidekiq::Job, ctx : Sidekiq::Context, &block : -> Bool) : Bool
    performer_id = job.extra_params["performer_id"]?.try(&.as_i64?)
    Current.set_performer_id(performer_id)

    yield
  ensure
    Current.clear
  end
end
