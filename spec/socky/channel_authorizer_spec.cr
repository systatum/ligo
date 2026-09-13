require "../spec_helper"

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
      received_user = uninitialized Ligo::User

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
      Socky::ChannelAuthorizer.register_resolver("duplicate_ns") { |_u, _k| true }

      expect_raises(Exception, "already registered") do
        Socky::ChannelAuthorizer.register_resolver("duplicate_ns") { |_u, _k| true }
      end
    end
  end
end
