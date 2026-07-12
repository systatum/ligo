module Marten::Server
  def self.handlers
    handlers = previous_def.map(&.as(::HTTP::Handler))

    middleware_index = handlers.index { |h| h.is_a?(Handlers::Middleware) }
    routing_index = handlers.index { |h| h.is_a?(Handlers::Routing) }

    unless middleware_index && routing_index && middleware_index < routing_index
      raise "Can't safely insert Socky::Handler"
    end

    handlers.insert(middleware_index, Socky::Handler.new)
    handlers
  end
end
