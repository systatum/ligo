require "../spec_helper"

describe Ligo::User do
  describe "#jwt_token / .find_by_jwt_token" do
    it "resolves the user that issued the token" do
      user = create_user
      token = user.jwt_token

      found = Ligo::User.find_by_jwt_token(token)

      found.should_not be_nil
      found.not_nil!.id.should eq user.id
    end

    it "rejects a token issued before the password was last changed" do
      user = create_user
      token = user.jwt_token

      user.set_password("a-brand-new-password")
      user.save!

      Ligo::User.find_by_jwt_token(token).should be_nil
    end
  end
end
