require "../../spec_helper"

describe Workaty::EmployeeDeleteHandler do
  describe "#delete" do
    context "when the user is authorized to delete the record" do
      it "can be deleted" do
        user = create_user
        employee = create_employee(adder: user)
        employee.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("workaty:employee:delete", employee_slug: employee.slug!),
          headers: {authorization: "Bearer #{user.jwt_token}"},
        )

        response.status.should eq 200

        deleted_employee = Workaty::Employee.unscoped.get!(id: employee.id)
        deleted_employee.id.should eq employee.id
        deleted_employee.deleted_at.should be_a Time

        response.content.should eq Workaty::EmployeeSerializer.serialize(deleted_employee)
      end
    end

    context "when the user belongs to a different organization" do
      it "will not be deleted" do
        user = create_user
        other_user = create_user
        employee = create_employee(adder: user)
        employee.deleted_at.should be_nil

        response = Marten::Spec.client.delete(
          Marten.routes.reverse("workaty:employee:delete", employee_slug: employee.slug!),
          headers: {authorization: "Bearer #{other_user.jwt_token}"},
        )

        response.status.should eq 404
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)

        employee.reload
        employee.deleted_at.should be_nil
      end
    end
  end
end
