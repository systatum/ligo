require "../user_factory"
require "./business_factory"

def create_space(
  manager : Auth::User = create_user,
  business : Antrikan::Business = create_business(owner: manager),
  name : String = "My Space",
  need_manual_approval : Bool = true,
  has_operating_hours : Bool = false,
  require_registered_queuer : Bool = false,
) : Antrikan::Space
  space = Antrikan::Space.new
  space.manager = manager
  space.owner = business
  space.name = name
  space.need_manual_approval = need_manual_approval
  space.has_operating_hours = has_operating_hours
  space.require_registered_queuer = require_registered_queuer
  space.save!

  space
end
