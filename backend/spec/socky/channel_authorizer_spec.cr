require "./spec_helper"

describe Socky::ChannelAuthorizer do
  describe ".can_access?" do
    it "returns false for malformed key without namespace separator" do
      user = create_user
      Socky::ChannelAuthorizer.can_access?(user, "no_colon_here").should be_false
    end

    it "returns false for unknown namespace" do
      user = create_user
      Socky::ChannelAuthorizer.can_access?(user, "unknown_ns:foo").should be_false
    end

    it "dispatches to the registered resolver and returns true" do
      user = create_user
      Socky::ChannelAuthorizer.register_resolver("test_true") do |_user, _local_key|
        true
      end

      Socky::ChannelAuthorizer.can_access?(user, "test_true:anything").should be_true
    end

    it "dispatches to the registered resolver and returns false" do
      user = create_user
      Socky::ChannelAuthorizer.register_resolver("test_false") do |_user, _local_key|
        false
      end

      Socky::ChannelAuthorizer.can_access?(user, "test_false:anything").should be_false
    end

    it "passes the local key (after the colon) to the resolver" do
      user = create_user
      received_key = ""

      Socky::ChannelAuthorizer.register_resolver("test_key_capture") do |_user, local_key|
        received_key = local_key
        true
      end

      Socky::ChannelAuthorizer.can_access?(user, "test_key_capture:my_local_id")
      received_key.should eq("my_local_id")
    end

    it "passes the user to the resolver" do
      user = create_user
      received_user = uninitialized Auth::User

      Socky::ChannelAuthorizer.register_resolver("test_user_capture") do |u, _local_key|
        received_user = u
        true
      end

      Socky::ChannelAuthorizer.can_access?(user, "test_user_capture:foo")
      received_user.id.should eq(user.id)
    end
  end

  describe ".register_resolver" do
    it "raises on duplicate namespace" do
      expect_raises(Exception, "already registered") do
        Socky::ChannelAuthorizer.register_resolver("antrikan") { |_u, _k| true }
      end
    end
  end

  describe "antrikan resolver (registered at boot)" do
    it "returns true for a user in the same organization as the channel space owner" do
      org = create_organization
      user = create_user(organization: org, role: Auth::Role::OWNER)
      space = create_space(manager: user)
      channel = create_channel(space: space)

      Socky::ChannelAuthorizer.can_access?(user, "antrikan:#{channel.hashed_id}").should be_true
    end

    it "returns false for a user in a different organization" do
      org_a = create_organization
      org_b = create_organization
      owner = create_user(organization: org_a, role: Auth::Role::OWNER)
      outsider = create_user(organization: org_b)
      space = create_space(manager: owner)
      channel = create_channel(space: space)

      Socky::ChannelAuthorizer.can_access?(outsider, "antrikan:#{channel.hashed_id}").should be_false
    end

    it "returns false for a non-existent channel hashed_id" do
      user = create_user
      Socky::ChannelAuthorizer.can_access?(user, "antrikan:nonexistent_hashed_id").should be_false
    end
  end
end
