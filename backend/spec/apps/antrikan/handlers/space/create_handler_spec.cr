require "./spec_helper"

describe Antrikan::SpaceCreateHandler do
  context "when the user is authorized" do
    context "with a valid schema" do
      it "creates a new space with auto-generated code" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {name: "My Queue Space"}.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.owner_id.should eq user.id
        space.name.should eq "My Queue Space"
        space.code!.size.should eq 5

        response.content.should eq Antrikan::SpaceSerializer.serialize(space)
      end

      it "creates a space with optional fields" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: {
            name:                 "Premium Queue",
            need_manual_approval: true,
            has_operating_hours:  true,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 201

        space = Antrikan::Space.last!
        space.name.should eq "Premium Queue"
        space.need_manual_approval.should be_true
        space.has_operating_hours.should be_true

        response.content.should eq Antrikan::SpaceSerializer.serialize(space)
      end
    end

    context "with an invalid schema" do
      it "raises an error" do
        user = create_user

        response = Marten::Spec.client.post(
          Marten.routes.reverse("antrikan:space:create"),
          data: ({} of String => String).to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
      end
    end
  end

  context "when the user is not authorized" do
    it "returns 400" do
      response = Marten::Spec.client.post(
        Marten.routes.reverse("antrikan:space:create"),
        data: {name: "Test Space"}.to_json,
        content_type: "application/json"
      )

      response.status.should eq 400
    end
  end
end
