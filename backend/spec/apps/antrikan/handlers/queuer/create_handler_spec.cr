require "./spec_helper"

describe Antrikan::QueuerCreateHandler do
  describe "#post" do
    it "creates a queuer and returns it with the plain password" do
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queuer:create", space_hashed_id: space.hashed_id),
        data: {name: "Table 1"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queuer = Antrikan::Queuer.last!
      queuer.name.should eq "Table 1"
      queuer.space_id.should eq space.id
      queuer.user_id.should be_nil
      queuer.password_hash.should_not be_nil

      parsed = JSON.parse(response.content)
      parsed["queuer"].to_json.should eq Antrikan::QueuerSerializer.serialize(queuer)
      parsed["password"].to_json.should_not be_nil
    end

    it "does not expose password_hash in the response" do
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queuer:create", space_hashed_id: space.hashed_id),
        data: {name: "Table 2"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201
      response.content.should_not contain "password_hash"
    end

    it "stores a bcrypt-hashed password that verifies against the returned plain password" do
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queuer:create", space_hashed_id: space.hashed_id),
        data: {name: "Table 3"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      plain = JSON.parse(response.content)["password"].as_s
      queuer = Antrikan::Queuer.last!
      Crypto::Bcrypt::Password.new(queuer.password_hash!).verify(plain).should be_true
    end

    it "creates a queuer associated with a user when user_id is provided" do
      space = create_space
      user = create_user

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queuer:create", space_hashed_id: space.hashed_id),
        data: {name: "Table 4", user_id: user.hashed_id}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 201

      queuer = Antrikan::Queuer.last!
      queuer.user_id.should eq user.id
    end

    it "returns 422 when name is missing" do
      space = create_space

      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queuer:create", space_hashed_id: space.hashed_id),
        data: ({} of String => String).to_json,
        content_type: "application/json"
      )

      response.status.should eq 422
    end

    it "returns 404 when the space does not exist" do
      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:queuer:create", space_hashed_id: IdConcealer.encode(999999999)),
        data: {name: "Table 5"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 404
    end

    context "when the space requires a registered user" do
      it "returns 422 if no user_id is provided" do
        space = create_space(require_registered_queuer: true)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:queuer:create", space_hashed_id: space.hashed_id),
          data: {name: "Table 1"}.to_json,
          content_type: "application/json"
        )

        response.status.should eq 422
        Antrikan::Queuer.filter(space_id: space.id).count.should eq 0
      end

      it "succeeds when a valid user_id is provided" do
        user = create_user
        space = create_space(require_registered_queuer: true)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:queuer:create", space_hashed_id: space.hashed_id),
          data: {name: "Table 1", user_id: user.hashed_id}.to_json,
          content_type: "application/json"
        )

        response.status.should eq 201
        Antrikan::Queuer.last!.user_id.should eq user.id
      end
    end
  end
end
