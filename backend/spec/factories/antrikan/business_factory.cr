require "../user_factory"

def create_business(
  owner : Auth::User = create_user,
  name : String = "Test Business",
) : Antrikan::Business
  business = Antrikan::Business.new
  business.owner = owner
  business.name = name
  business.save!

  business
end
