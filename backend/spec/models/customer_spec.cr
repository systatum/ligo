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

  it "tracks changes" do
    c = Customer.new
    c.first_name = "Adam"
    c.save.should be_true
    c.created_at.should_not eq nil
    c.updated_at.should_not eq nil

    # assert the first change log
    Changelog.filter(record_class: "Customer", record_id: c.id).all.size.should eq 1
    log = Changelog.last!
    log.action_type.should eq Changelog::ActionType::CREATE
    log.record_class.should eq "Customer"
    log.record_id.should eq c.id
    changes = log.changes!
    changes.size.should eq 2
    changes["id"]["type"].should eq "int"
    changes["id"]["current_value"].should eq 1
    changes["id"]["old_value"].should eq nil
    changes["first_name"]["type"].should eq "text"
    changes["first_name"]["current_value"].should eq "Adam"
    changes["first_name"]["old_value"].should eq nil

    # make an update and assert the second change log
    c.first_name = "Tifa"
    c.middle_name = "Princess"
    c.last_name = "Humholdt"
    c.gender = Gender::MALE
    c.birthday = Time.unix(1000000000)
    c.note = "Cool customer"
    c.save
    log2 = Changelog.last!
    log2.id.should_not eq log.id
    log2.action_type.should eq Changelog::ActionType::UPDATE
    log2.record_class.should eq "Customer"
    log2.record_id.should eq c.id
    changes2 = log2.changes!
    changes2["first_name"]["type"].should eq "text"
    changes2["first_name"]["current_value"].should eq "Tifa"
    changes2["first_name"]["old_value"].should eq "Adam"
    changes2["middle_name"]["type"].should eq "text"
    changes2["middle_name"]["current_value"].should eq "Princess"
    changes2["middle_name"]["old_value"].should eq nil
    changes2["last_name"]["type"].should eq "text"
    changes2["last_name"]["current_value"].should eq "Humholdt"
    changes2["last_name"]["old_value"].should eq nil
    changes2["gender"]["type"].should eq "int"
    changes2["gender"]["current_value"].should eq Gender::MALE
    changes2["gender"]["old_value"].should eq nil
    changes2["birthday"]["type"].should eq "date"
    changes2["birthday"]["current_value"].should eq "2001-09-09 00:00:00 UTC"
    changes2["birthday"]["old_value"].should eq nil
    changes2["note"]["type"].should eq "text"
    changes2["note"]["current_value"].should eq "Cool customer"
    changes2["note"]["old_value"].should eq nil
    changes2.size.should eq 6

    # track deletion
    c.delete
    log3 = Changelog.last!
    log3.id.should_not eq log2.id
    log3.action_type.should eq Changelog::ActionType::DELETE
    log3.record_class.should eq "Customer"
    log3.record_id.should eq c.id
    changes3 = log3.changes!
    changes3.size.should eq 0
  end

  it "can be soft deleted" do
    c = Customer.new
    c.first_name = "Adam"
    c.save!

    c.soft_delete
    c2 = Customer.get(id: c.id)
    c2.should be nil # because it's soft-deleted
  end
end
