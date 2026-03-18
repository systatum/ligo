require "./spec_helper"

describe Antrikan::SpaceQrHandler do
  describe "#get" do
    context "when the user is authorized" do
      it "returns QR code as Base64 PNG" do
        user = create_user
        space = create_space(owner: user, name: "QR Test Space")

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:qr", space_hashed_id: space.hashed_id),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 200

        json = JSON.parse(response.content)
        json["code"].should eq space.code
        json["qr_base64"].as_s.should_not be_empty
        json["content_type"].should eq "image/png"

        # Verify it's valid base64
        decoded = Base64.decode(json["qr_base64"].as_s)
        decoded.should_not be_empty

        # PNG magic bytes check (first 8 bytes)
        decoded[0].should eq 0x89_u8
        decoded[1].should eq 0x50_u8 # P
        decoded[2].should eq 0x4E_u8 # N
        decoded[3].should eq 0x47_u8 # G
      end

      it "returns 404 when space does not exist" do
        user = create_user
        fake_hashed_id = IdConcealer.encode(999999999)

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:qr", space_hashed_id: fake_hashed_id),
          headers: {authorization: "Bearer #{user.jwt_token}"}
        )

        response.status.should eq 404
      end

      it "returns 403 when space belongs to another user" do
        user1 = create_user
        user2 = create_user
        space = create_space(owner: user2, name: "Other User Space")

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:qr", space_hashed_id: space.hashed_id),
          headers: {authorization: "Bearer #{user1.jwt_token}"}
        )

        response.status.should eq 403
      end
    end

    context "when the user is not authorized" do
      it "returns 400" do
        user = create_user
        space = create_space(owner: user)

        response = Marten::Spec.client.get(
          Marten.routes.reverse("antrikan:space:qr", space_hashed_id: space.hashed_id)
        )

        response.status.should eq 400
      end
    end
  end
end
