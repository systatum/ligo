require "./spec_helper"

describe Antrikan::QueuerShowHandler do
  context "when the queuer exists" do
    it "returns queuer info" do
      queuer = create_queuer(
        home_address: "Jl. Mawar No. 5",
        mobile_phone: "081122334455",
        note: "Ring the bell",
      )

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:queuer:show", queuer_hashed_id: queuer.hashed_id)
      )

      response.status.should eq 200
      response.content.should eq Antrikan::QueuerSerializer.serialize(queuer)
    end

    it "does not include password_hash in the response" do
      queuer = create_queuer

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:queuer:show", queuer_hashed_id: queuer.hashed_id)
      )

      response.content.should_not contain "password_hash"
    end
  end

  context "when the queuer is soft-deleted" do
    it "returns 404" do
      queuer = create_queuer
      queuer.soft_delete!

      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:queuer:show", queuer_hashed_id: queuer.hashed_id)
      )

      response.status.should eq 404
    end
  end

  context "when the queuer does not exist" do
    it "returns 404" do
      response = Marten::Spec.client.get(
        Marten.routes.reverse("antrikan:queuer:show", queuer_hashed_id: IdConcealer.encode(999999999))
      )

      response.status.should eq 404
    end
  end
end
