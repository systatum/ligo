require "./spec_helper"

require "./concerns/email_template_fields"

Spectator.describe Workaty::EmailTemplateDeleteHandler do
  include EmailTemplateFields

  context "when the user is authorized" do
    it "soft deletes the template" do
      user = create_user
      template = create_email_template(adder: user)
      expect(template.deleted_at).to be_nil

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("workaty:email:template:delete", template_hashed_id: template.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      expect(response.status).to eq(204)

      deleted_template = Workaty::EmailTemplate.unscoped.get!(id: template.id)
      expect(deleted_template.deleted_at).to be_a(Time)
    end
  end

  context "when template belongs to different organization" do
    it "returns 404" do
      user = create_user
      other_user = create_user
      template = create_email_template(adder: other_user)

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("workaty:email:template:delete", template_hashed_id: template.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      expect(response.status).to eq(404)

      template.reload
      expect(template.deleted_at).to be_nil
    end
  end

  context "when user is not authorized" do
    it "returns 403" do
      user = create_user(role: Auth::Role::SECURITY_STAFF)
      template = create_email_template(adder: create_user(organization: user.organization!))

      response = Marten::Spec.client.delete(
        Marten.routes.reverse("workaty:email:template:delete", template_hashed_id: template.hashed_id),
        headers: {authorization: "Bearer #{user.jwt_token}"}
      )

      expect(response.status).to eq(403)

      template.reload
      expect(template.deleted_at).to be_nil
    end
  end
end
