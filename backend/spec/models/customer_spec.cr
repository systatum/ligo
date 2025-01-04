require "../spec_helper"

describe Customer do
  describe ".new" do
    it "sets the slug" do
      c = Customer.new
      c.slug!.empty?.should be_false
    end
  end

  describe "#save" do
    it "can be created with just the first name" do
      c = Customer.new
      c.first_name = "Adam"
      c.save.should be_true

      c.first_name.should eq "Adam"
    end
  end
end
