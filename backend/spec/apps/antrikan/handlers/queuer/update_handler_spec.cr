require "./spec_helper"

describe Antrikan::QueuerUpdateHandler do
  it "updates the name when the password matches" do
    space = create_space
    queuer = create_queuer(space: space, name: "Old Name", password: "secret123")

    response = Marten::Spec.client.patch(
      Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
      data: {queuer_id: queuer.hashed_id, password: "secret123", name: "New Name"}.to_json,
      content_type: "application/json"
    )

    response.status.should eq 200

    queuer.reload
    queuer.name.should eq "New Name"
    response.content.should eq Antrikan::QueuerSerializer.serialize(queuer)
  end

  it "updates the optional profile fields when present" do
    space = create_space
    queuer = create_queuer(space: space, password: "secret123")

    response = Marten::Spec.client.patch(
      Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
      data: {
        queuer_id:    queuer.hashed_id,
        password:     "secret123",
        home_address: "Jl. Kenanga No. 2",
        mobile_phone: "08999888777",
        note:         "Allergic to peanuts",
      }.to_json,
      content_type: "application/json"
    )

    response.status.should eq 200

    queuer.reload
    queuer.home_address.should eq "Jl. Kenanga No. 2"
    queuer.mobile_phone.should eq "08999888777"
    queuer.note.should eq "Allergic to peanuts"
  end

  it "clears optional profile fields when sent as null" do
    space = create_space
    queuer = create_queuer(
      space: space,
      home_address: "Jl. Lama No. 9",
      mobile_phone: "08000000000",
      note: "Existing note",
      password: "secret123"
    )

    response = Marten::Spec.client.patch(
      Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
      data: {
        queuer_id:    queuer.hashed_id,
        password:     "secret123",
        home_address: nil,
        mobile_phone: nil,
        note:         nil,
      }.to_json,
      content_type: "application/json"
    )

    response.status.should eq 200

    queuer.reload
    queuer.home_address.should be_nil
    queuer.mobile_phone.should be_nil
    queuer.note.should be_nil
  end

  it "associates a user when user_id is provided" do
    space = create_space
    queuer = create_queuer(space: space, password: "secret123")
    user = create_user

    response = Marten::Spec.client.patch(
      Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
      data: {queuer_id: queuer.hashed_id, password: "secret123", user_id: user.hashed_id}.to_json,
      content_type: "application/json"
    )

    response.status.should eq 200

    queuer.reload
    queuer.user_id.should eq user.id
  end

  it "clears user_id when sent as null" do
    user = create_user
    space = create_space
    queuer = create_queuer(space: space, user: user, password: "secret123")

    response = Marten::Spec.client.patch(
      Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
      data: {queuer_id: queuer.hashed_id, password: "secret123", user_id: nil}.to_json,
      content_type: "application/json"
    )

    response.status.should eq 200

    queuer.reload
    queuer.user_id.should be_nil
  end

  it "does not change fields not present in the request body" do
    space = create_space
    queuer = create_queuer(space: space, name: "Original", password: "secret123")

    response = Marten::Spec.client.patch(
      Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
      data: {queuer_id: queuer.hashed_id, password: "secret123"}.to_json,
      content_type: "application/json"
    )

    response.status.should eq 200

    queuer.reload
    queuer.name.should eq "Original"
  end

  context "when the password is wrong" do
    it "returns 422 and does not update the queuer" do
      space = create_space
      queuer = create_queuer(space: space, name: "Original", password: "correctpassword")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
        data: {queuer_id: queuer.hashed_id, password: "wrongpassword", name: "Changed"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422

      queuer.reload
      queuer.name.should eq "Original"
    end
  end

  context "when queuer_id belongs to a different space" do
    it "returns 404" do
      space = create_space
      other_space = create_space
      queuer = create_queuer(space: other_space, password: "secret123")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
        data: {queuer_id: queuer.hashed_id, password: "secret123"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404
    end
  end

  context "when queuer_id is missing" do
    it "returns 422" do
      space = create_space

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
        data: {password: "secret123", name: "New Name"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when password is missing" do
    it "returns 422" do
      space = create_space
      queuer = create_queuer(space: space)

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
        data: {queuer_id: queuer.hashed_id, name: "New Name"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end
  end

  context "when the space requires a registered user" do
    it "returns 422 when clearing user_id to null" do
      user = create_user
      space = create_space(require_registered_queuer: true)
      queuer = create_queuer(space: space, user: user, password: "secret123")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
        data: {queuer_id: queuer.hashed_id, password: "secret123", user_id: nil}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 422

      queuer.reload
      queuer.user_id.should eq user.id
    end

    it "allows updating other fields while keeping the user" do
      user = create_user
      space = create_space(require_registered_queuer: true)
      queuer = create_queuer(space: space, user: user, name: "Old Name", password: "secret123")

      response = Marten::Spec.client.patch(
        Marten.routes.reverse("antrikan:space:queuer:update", space_hashed_id: space.hashed_id),
        data: {queuer_id: queuer.hashed_id, password: "secret123", name: "New Name"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 200

      queuer.reload
      queuer.name.should eq "New Name"
      queuer.user_id.should eq user.id
    end
  end
end
