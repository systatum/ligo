require "./spec_helper"

describe Antrikan::QueuerIndexHandler do
  describe "#get" do
    it "returns all active queuers of a space" do
      space = create_space
      q1 = create_queuer(space: space, name: "Q1")
      q2 = create_queuer(space: space, name: "Q2")
      other = create_queuer(name: "Other Space Queuer")

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:queuer:index", space_hashed_id: space.hashed_id)
      )

      response.status.should eq 200

      json_response = JSON.parse(response.content)
      records = json_response["queuers"].as_a
      records.size.should eq 2

      records[0]["id"].should eq q1.hashed_id
      records[0]["space_id"].should eq space.hashed_id
      records[0]["user_id"].should eq nil
      records[0]["name"].should eq q1.name

      records[1]["id"].should eq q2.hashed_id
      records[1]["space_id"].should eq space.hashed_id
      records[1]["user_id"].should eq nil
      records[1]["name"].should eq q2.name
    end

    it "excludes soft-deleted queuers by default" do
      space = create_space
      active = create_queuer(space: space, name: "Active")
      deleted = create_queuer(space: space, name: "Deleted")
      deleted.soft_delete!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:queuer:index", space_hashed_id: space.hashed_id)
      )

      response.status.should eq 200

      ids = JSON.parse(response.content)["queuers"].as_a.map { |q| q["id"].as_s }.to_set
      ids.should contain active.hashed_id
      ids.should_not contain deleted.hashed_id
    end

    context "when ?with_deleted=true" do
      it "includes soft-deleted queuers" do
        space = create_space
        active = create_queuer(space: space, name: "Active")
        deleted = create_queuer(space: space, name: "Deleted")
        deleted.soft_delete!

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:queuer:index", space_hashed_id: space.hashed_id),
          query_params: {with_deleted: "true"}
        )

        response.status.should eq 200

        ids = JSON.parse(response.content)["queuers"].as_a.map { |q| q["id"].as_s }.to_set
        ids.should contain active.hashed_id
        ids.should contain deleted.hashed_id
      end
    end

    it "returns an empty list when the space has no queuers" do
      space = create_space

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:queuer:index", space_hashed_id: space.hashed_id)
      )

      response.status.should eq 200
      response.content.should eq({queuers: [] of String}.to_json)
    end
  end
end
