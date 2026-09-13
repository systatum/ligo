require "../../spec_helper"

class RequestAuthorizerSpecFixtureAuthorizer
  include Rbacr::Definer

  MANAGE            = act(:manage)
  CAN_MANAGE_WIDGET = can(MANAGE, :widget)

  OWNER_ROLE = role(:owner, [CAN_MANAGE_WIDGET])
  GUEST_ROLE = role(:guest)
end

class RequestAuthorizerSpecFixtureHandler
  include RequestAuthorizer

  def authorizer_class
    RequestAuthorizerSpecFixtureAuthorizer
  end
end

describe RequestAuthorizer do
  it "delegates can? to the including handler's authorizer_class" do
    handler = RequestAuthorizerSpecFixtureHandler.new

    handler.can?(RequestAuthorizerSpecFixtureAuthorizer::CAN_MANAGE_WIDGET, "owner").should be_true
    handler.can?(RequestAuthorizerSpecFixtureAuthorizer::CAN_MANAGE_WIDGET, "guest").should be_false
  end
end
