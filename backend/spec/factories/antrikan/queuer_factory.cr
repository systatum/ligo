require "../user_factory"
require "./space_factory"

def create_queuer(
  space : Antrikan::Space = create_space,
  user : Auth::User? = nil,
  name : String = "Queuer 1",
  password : String = "testpassword123",
) : Antrikan::Queuer
  queuer = Antrikan::Queuer.new
  queuer.space = space
  queuer.user = user
  queuer.name = name
  queuer.password_hash = Crypto::Bcrypt::Password.create(password, cost: 4).to_s
  queuer.save!

  queuer
end
