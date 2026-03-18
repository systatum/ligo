require "./spec_helper"

describe Antrikan::SpaceJoinHandler do
  describe "#post" do
    context "when the user is authorized" do
      it "returns 200 with empty added and failed when payload has no users" do
        owner = create_user
        space = create_space(owner: owner)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {
            users: [] of Antrikan::SpaceJoinUserPayload,
          }.to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200
        json = JSON.parse(response.content)
        json["added"].as_a.size.should eq 0
        json["failed"].as_a.size.should eq 0
      end

      it "returns 201 when at least one user is added successfully" do
        owner = create_user
        space = create_space(owner: owner)
        user_to_add = create_user
        before_member_count = space.members.count
        before_joined_spaces_count = user_to_add.joined_spaces.count

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {
            users: [
              {
                user_id: user_to_add.hashed_id,
              },
            ],
          }.to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201
        json = JSON.parse(response.content)
        json["added"].as_a.size.should eq 1
        json["added"][0]["id"].as_s.should eq user_to_add.hashed_id
        json["failed"].as_a.size.should eq 0
        space.members.filter(id: user_to_add.id!).count.should eq 1
        space.members.count.should eq before_member_count + 1
        user_to_add.joined_spaces.filter(id: space.id!).count.should eq 1
        user_to_add.joined_spaces.count.should eq before_joined_spaces_count + 1
      end

      it "returns 201 when payload includes non-existing and invalid user_ids" do
        owner = create_user
        space = create_space(owner: owner)
        user_to_add = create_user

        user_to_delete = create_user
        valid_but_non_existing_id = user_to_delete.hashed_id
        user_to_delete.delete

        invalid_id = "invalid-id"
        before_member_count = space.members.count
        before_joined_spaces_count = user_to_add.joined_spaces.count

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {
            users: [
              {
                user_id: user_to_add.hashed_id,
              },
              {
                user_id: valid_but_non_existing_id,
              },
              {
                user_id: invalid_id,
              },
            ],
          }.to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201
        json = JSON.parse(response.content)
        json["added"].as_a.size.should eq 1
        json["failed"].as_a.size.should eq 2

        failed_ids = json["failed"].as_a.map { |f| f["id"].as_s }
        failed_ids.should contain(valid_but_non_existing_id)
        failed_ids.should contain(invalid_id)

        space.members.filter(id: user_to_add.id!).count.should eq 1
        space.members.count.should eq before_member_count + 1
        user_to_add.joined_spaces.filter(id: space.id!).count.should eq 1
        user_to_add.joined_spaces.count.should eq before_joined_spaces_count + 1
      end

      it "returns 500 when all users are not found" do
        owner = create_user
        space = create_space(owner: owner)
        before_member_count = space.members.count

        user_to_delete = create_user
        valid_but_non_existing_id = user_to_delete.hashed_id
        user_to_delete.delete

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {
            users: [
              {
                user_id: "invalid_id_1",
              },
              {
                user_id: valid_but_non_existing_id,
              },
            ],
          }.to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 500
        json = JSON.parse(response.content)
        json["added"].as_a.size.should eq 0
        json["failed"].as_a.size.should eq 2
        failed_ids = json["failed"].as_a.map { |f| f["id"].as_s }
        failed_ids.should contain(valid_but_non_existing_id)
        failed_ids.should contain("invalid_id_1")
        space.members.count.should eq before_member_count
      end

      it "returns 201 when all users in the payload is already a member" do
        owner = create_user
        space = create_space(owner: owner)
        existing_member = create_user
        space.members.add(existing_member)
        before_member_count = space.members.count
        before_joined_spaces_count = existing_member.joined_spaces.count

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {
            users: [
              {
                user_id: existing_member.hashed_id,
              },
            ],
          }.to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201
        json = JSON.parse(response.content)
        json["added"].as_a.size.should eq 1
        json["failed"].as_a.size.should eq 0
        space.members.filter(id: existing_member.id!).count.should eq 1
        space.members.count.should eq before_member_count
        existing_member.joined_spaces.filter(id: space.id!).count.should eq 1
        existing_member.joined_spaces.count.should eq before_joined_spaces_count
      end

      it "returns 201 when payload contains duplicate user_id entries" do
        owner = create_user
        space = create_space(owner: owner)
        user_to_add = create_user
        before_member_count = space.members.count
        before_joined_spaces_count = user_to_add.joined_spaces.count

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {
            users: [
              {
                user_id: user_to_add.hashed_id,
              },
              {
                user_id: user_to_add.hashed_id,
              },
            ],
          }.to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201
        json = JSON.parse(response.content)
        json["added"].as_a.size.should eq 1
        json["failed"].as_a.size.should eq 0
        space.members.filter(id: user_to_add.id!).count.should eq 1
        space.members.count.should eq before_member_count + 1
        user_to_add.joined_spaces.filter(id: space.id!).count.should eq 1
        user_to_add.joined_spaces.count.should eq before_joined_spaces_count + 1
      end

      it "returns 200 with empty added and failed when payload does not include users" do
        owner = create_user
        space = create_space(owner: owner)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: ({} of String => String).to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 200
        json = JSON.parse(response.content)
        json["added"].as_a.size.should eq 0
        json["failed"].as_a.size.should eq 0
      end

      it "returns 422 when users is not an array" do
        owner = create_user
        space = create_space(owner: owner)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {users: "invalid"}.to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
      end

      it "returns 422 when a user entry is missing user_id" do
        owner = create_user
        space = create_space(owner: owner)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {
            users: [
              ({} of String => String),
            ],
          }.to_json,
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
      end

      it "returns 400 when payload JSON is malformed" do
        owner = create_user
        space = create_space(owner: owner)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: "{\"users\":[",
          headers: {authorization: "Bearer #{owner.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 400
      end

      it "returns 404 when space code does not exist" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: "ZZZZZ"),
          data: {
            users: [] of Hash(String, String),
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 404
      end
    end

    context "when the user is not authorized" do
      it "returns 400" do
        owner = create_user
        space = create_space(owner: owner)

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:code:join", space_code: space.code!),
          data: {
            users: [] of Hash(String, String),
          }.to_json,
          content_type: "application/json"
        )

        response.status.should eq 400
      end
    end
  end
end
