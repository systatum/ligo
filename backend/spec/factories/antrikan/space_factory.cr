require "../user_factory"

def create_space(
  owner : Auth::User = create_user,
  name : String = "My Space",
  need_manual_approval : Bool = true,
  has_operating_hours : Bool = false,
) : Antrikan::Space
  space = Antrikan::Space.new
  space.owner = owner
  space.name = name
  space.need_manual_approval = need_manual_approval
  space.has_operating_hours = has_operating_hours
  space.save!

  space
end
