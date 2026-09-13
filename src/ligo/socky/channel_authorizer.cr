module Socky::ChannelAuthorizer
  alias Resolver = Ligo::User, String -> Bool

  class_getter resolvers = Hash(String, Resolver).new

  def self.register_resolver(namespace : String, &resolver : Resolver) : Nil
    raise "Socky: resolver already registered for '#{namespace}'" if resolvers.has_key?(namespace)
    resolvers[namespace] = resolver
  end

  # channel_key is always "<namespace>:<app-local key>" (e.g. "antrikan:chnl_9K2f").
  def self.can_access?(user : Ligo::User, channel_key : String) : Bool
    parts = channel_key.split(":", 2)
    return false unless parts.size == 2

    namespace, local_key = parts
    resolvers[namespace]?.try(&.call(user, local_key)) || false
  end
end
