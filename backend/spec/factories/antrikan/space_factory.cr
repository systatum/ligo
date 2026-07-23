require "../user_factory"
require "./business_factory"

def create_space(
  manager : Auth::User = create_user,
  business : Antrikan::Business = create_business(owner: manager),
  name : String = "My Space",
  need_manual_approval : Bool = true,
  has_operating_hours : Bool = false,
  require_registered_queuer : Bool = false,
  address : String? = nil,
  latitude : Float64? = nil,
  longitude : Float64? = nil,
  address_city_code : Int32? = nil,
  address_postal_code : String? = nil,
) : Antrikan::Space
  space = Antrikan::Space.new
  space.manager = manager
  space.owner = business
  space.name = name
  space.need_manual_approval = need_manual_approval
  space.has_operating_hours = has_operating_hours
  space.require_registered_queuer = require_registered_queuer
  space.address = address
  space.latitude = latitude
  space.longitude = longitude
  space.address_city_code = address_city_code
  space.address_postal_code = address_postal_code
  space.save!

  space
end
