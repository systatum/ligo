require "../user_factory"
require "./space_factory"

def create_queuer(
  space : Antrikan::Space = create_space,
  user : Auth::User? = nil,
  name : String = "Queuer 1",
  home_address : String? = nil,
  mobile_phone : String? = nil,
  note : String? = nil,
  password : String = "testpassword123",
) : Antrikan::Queuer
  queuer = Antrikan::Queuer.new
  queuer.space = space
  queuer.user = user
  queuer.name = name
  queuer.home_address = home_address
  queuer.mobile_phone = mobile_phone
  queuer.note = note
  queuer.password_hash = Crypto::Bcrypt::Password.create(password, cost: 4).to_s
  queuer.save!

  queuer
end
