require "./spec_helper"

describe Antrikan::VoucherIndexHandler do
  context "when the user owns the space" do
    it "returns vouchers for the space" do
      user = create_user
      space = create_space(manager: user)
      voucher1 = create_voucher(space: space)
      voucher2 = create_voucher(space: space)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:voucher:index", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should contain voucher1.hashed_id
      response.content.should contain voucher2.hashed_id
    end

    it "does not return vouchers from other spaces" do
      user = create_user
      space1 = create_space(manager: user)
      space2 = create_space(manager: user)
      voucher1 = create_voucher(space: space1)
      voucher2 = create_voucher(space: space2)

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:voucher:index", space_hashed_id: space1.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should contain voucher1.hashed_id
      response.content.should_not contain voucher2.hashed_id
    end

    it "does not return soft-deleted vouchers" do
      user = create_user
      space = create_space(manager: user)
      voucher1 = create_voucher(space: space)
      voucher2 = create_voucher(space: space)
      voucher2.soft_delete!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:voucher:index", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should contain voucher1.hashed_id
      response.content.should_not contain voucher2.hashed_id
    end

    it "includes soft-deleted vouchers when with_deleted=true" do
      user = create_user
      space = create_space(manager: user)
      voucher = create_voucher(space: space)
      voucher.soft_delete!

      response = Marten::Spec.client.get(
        "#{Marten.routes.reverse("antrikan:space:voucher:index", space_hashed_id: space.hashed_id)}?with_deleted=true",
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      response.status.should eq 200
      response.content.should contain voucher.hashed_id
    end
  end

  context "when the user does not own the space" do
    it "returns 403" do
      space = create_space
      other_user = create_user

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:voucher:index", space_hashed_id: space.hashed_id),
        headers: {authorization: "Bearer #{other_user.jwt_token}"}
      )

      response.status.should eq 403
    end
  end

  context "when the user is not authenticated" do
    it "returns 400" do
      space = create_space

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:space:voucher:index", space_hashed_id: space.hashed_id)
      )

      response.status.should eq 400
    end
  end
end
