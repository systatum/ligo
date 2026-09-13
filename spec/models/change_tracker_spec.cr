require "../spec_helper"

describe ChangeTracker do
  it "records a changelog entry on create, update and delete" do
    user = create_user

    create_log = Ligo::Changelog.filter(
      record_class: "Ligo::User",
      record_id: user.id,
      action_type: Ligo::Changelog::ActionType::CREATE
    ).first
    create_log.should_not be_nil

    user.first_name = "Renamed"
    user.save!

    update_log = Ligo::Changelog.filter(
      record_class: "Ligo::User",
      record_id: user.id,
      action_type: Ligo::Changelog::ActionType::UPDATE
    ).first
    update_log.should_not be_nil
    update_log.not_nil!.changes.to_s.should contain "first_name"

    user_id = user.id
    user.delete

    delete_log = Ligo::Changelog.filter(
      record_class: "Ligo::User",
      record_id: user_id,
      action_type: Ligo::Changelog::ActionType::DELETE
    ).first
    delete_log.should_not be_nil
  end

  it "records the performer id from Current on the changelog entry" do
    performer = create_user
    Current.set_performer_id(performer.id)

    tracked = create_user

    log = Ligo::Changelog.filter(
      record_class: "Ligo::User",
      record_id: tracked.id,
      action_type: Ligo::Changelog::ActionType::CREATE
    ).first.not_nil!

    log.performer_id.should eq performer.id
  ensure
    Current.clear
  end
end
