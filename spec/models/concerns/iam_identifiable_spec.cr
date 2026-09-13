require "../../spec_helper"

describe IamIdentifiable do
  it "returns the existing user when iam_identifier_primary matches" do
    user = create_user(email: "iam-existing@example.com")
    user.ensure_iam_identifier!
    identifier = user.iam_identifier_primary.not_nil!

    result = Ligo::User.find_or_create_by_iam_identifier(
      iam_identifier_primary: identifier,
      user_info: IamIdentifiable::UserInfo.new(
        given_name: "Existing",
        family_name: "User",
        email: user.email.not_nil!,
        role: Role::OWNER
      )
    )

    result.id.should eq(user.id)
    result.iam_identifier_primary.should eq(identifier)
  end

  it "binds iam_identifier_primary to an email-matched user when missing" do
    user = create_user(email: "iam-bind@example.com")
    user.iam_identifier_primary.should be_nil

    incoming_identifier = "auth:test-identifier-123"

    result = Ligo::User.find_or_create_by_iam_identifier(
      iam_identifier_primary: incoming_identifier,
      user_info: IamIdentifiable::UserInfo.new(
        given_name: "Bind",
        family_name: "User",
        email: user.email.not_nil!,
        role: Role::OWNER
      )
    )

    result.id.should eq(user.id)
    result.iam_identifier_primary.should eq(incoming_identifier)
  end

  it "raises when an email-matched user already has a different iam_identifier_primary" do
    user = create_user(email: "iam-conflict@example.com")
    user.ensure_iam_identifier!
    existing_identifier = user.iam_identifier_primary.not_nil!

    expect_raises(ArgumentError, /mismatch/) do
      Ligo::User.find_or_create_by_iam_identifier(
        iam_identifier_primary: "auth:rotated-identifier",
        user_info: IamIdentifiable::UserInfo.new(
          given_name: "Conflict",
          family_name: "User",
          email: user.email.not_nil!,
          role: Role::OWNER
        )
      )
    end

    user.reload
    user.iam_identifier_primary.should eq(existing_identifier)
  end
end
