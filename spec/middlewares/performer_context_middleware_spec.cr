require "../spec_helper"

class PerformerContextMiddlewareSpecFixtureContext < Sidekiq::Context
  getter pool : Sidekiq::Pool
  getter logger : ::Log
  getter error_handlers : Array(Sidekiq::ExceptionHandler::Base)

  def initialize
    @pool = Sidekiq::Pool.new(1)
    @logger = ::Log.for("performer-context-spec")
    @error_handlers = [] of Sidekiq::ExceptionHandler::Base
  end
end

describe PerformerContextPropagator do
  it "attaches the current performer id onto the job's extra params" do
    Current.set_performer_id(42_i64)

    job = Sidekiq::Job.new
    ctx = PerformerContextMiddlewareSpecFixtureContext.new

    PerformerContextPropagator.new.call(job, ctx) { true }

    job.extra_params["performer_id"].as_i64.should eq 42
  ensure
    Current.clear
  end

  it "does not add extra params when there is no current performer" do
    Current.clear

    job = Sidekiq::Job.new
    ctx = PerformerContextMiddlewareSpecFixtureContext.new

    PerformerContextPropagator.new.call(job, ctx) { true }

    job.extra_params.has_key?("performer_id").should be_false
  end
end

describe PerformerContextRestorer do
  it "restores the performer id for the duration of the job and clears it after" do
    job = Sidekiq::Job.new
    job.extra_params = {"performer_id" => JSON::Any.new(99_i64)}
    ctx = PerformerContextMiddlewareSpecFixtureContext.new

    seen_performer_id = nil

    PerformerContextRestorer.new.call(job, ctx) do
      seen_performer_id = Current.performer_id
      true
    end

    seen_performer_id.should eq 99
    Current.performer_id.should be_nil
  end
end
