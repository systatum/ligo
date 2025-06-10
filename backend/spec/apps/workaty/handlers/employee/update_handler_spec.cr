require "../../spec_helper"

describe Workaty::EmployeeUpdateHandler do
  describe "#patch" do
    context "when the employee cannot be found" do
      it "renders 404" do
        user = create_user

        response = Marten::Spec.client.patch(
          Marten.routes.reverse("workaty:employee:update", employee_slug: "nonexistent"),
          data: {
            first_name: "John",
            last_name:  "Doe",
            email:      "john.doe@example.org",
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json",
        )

        response.status.should eq 404
        response.content.should eq({error: {messages: ["Not found"]}}.to_json)
      end
    end

    context "when the employee can be found" do
      context "when the user is authorized" do
        it "will be updated" do
          user = create_user
          employee = create_employee(adder: user)

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:employee:update", employee_slug: employee.slug!),
            data: {
              first_name: "Adam",
              last_name:  "Hakarsa",
              email:      "adam@example.org",
              phone:      123456,
              note:       "Updated note",
            }.to_json,
            headers: {authorization: "Bearer #{user.jwt_token}"},
            content_type: "application/json",
          )

          response.status.should eq 200

          employee.reload
          employee.first_name.should eq "Adam"
          employee.last_name.should eq "Hakarsa"
          employee.email.should eq "adam@example.org"
          employee.phone.should eq 123456
          employee.note.should eq "Updated note"
          employee.deleted_at.should be_nil

          response.content.should eq Workaty::EmployeeSerializer.serialize(employee)
        end
      end

      context "when the user belongs to a different organization" do
        it "won't be updated" do
          user = create_user
          other_user = create_user
          employee = create_employee(adder: user)

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:employee:update", employee_slug: employee.slug!),
            data: {
              first_name: "Adam",
              last_name:  "Hakarsa",
            }.to_json,
            headers: {authorization: "Bearer #{other_user.jwt_token}"},
            content_type: "application/json",
          )

          response.status.should eq 404
          response.content.should eq({error: {messages: ["Not found"]}}.to_json)

          employee.reload
          employee.first_name.should_not eq "Adam"
          employee.last_name.should_not eq "Hakarsa"
        end
      end

      context "when the user is not authorized to update" do
        it "won't be updated" do
          user = create_user
          employee = create_employee(adder: user)
          other_user = create_user role: Auth::Role::SECURITY_STAFF, organization: user.organization!

          response = Marten::Spec.client.patch(
            Marten.routes.reverse("workaty:employee:update", employee_slug: employee.slug!),
            data: {
              first_name: "Adam",
              last_name:  "Hakarsa",
            }.to_json,
            headers: {authorization: "Bearer #{other_user.jwt_token}"},
            content_type: "application/json",
          )

          response.status.should eq 403
          employee.reload
          employee.first_name.should_not eq "Adam"
          employee.last_name.should_not eq "Hakarsa"
          response.content.should eq({error: {messages: ["Not authorized"]}}.to_json)
        end
      end
    end
  end
end
