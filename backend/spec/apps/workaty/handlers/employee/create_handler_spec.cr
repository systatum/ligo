require "../../spec_helper"

describe Workaty::EmployeeCreateHandler do
  context "with valid schema" do
    it "creates a new employee" do
      user = create_user
      response = Marten::Spec.client.post(
        Marten.routes.reverse("workaty:employee:create"),
        data: {
          first_name: "Steve",
          last_name:  "Evets",
          email:      "steve@example.com",
          phone:      "081529891111",
          note:       "This is a note",
        }.to_json,
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      emp = Workaty::Employee.last!
      emp.organization.should eq user.organization
      emp.first_name.should eq "Steve"
      emp.last_name.should eq "Evets"
      emp.email.should eq "steve@example.com"
      emp.phone.should eq 81529891111
      emp.note.should eq "This is a note"
      emp.created_at.should_not be_nil
      emp.updated_at.should_not be_nil
      emp.deleted_at.should be_nil

      response.content.should eq Workaty::EmployeeSerializer.serialize(emp)
    end

    context "with email that has already been registered" do
      it "raises an error" do
        user = create_user
        employee = create_employee(adder: user)
        response = Marten::Spec.client.post(
          Marten.routes.reverse("workaty:employee:create"),
          data: {
            first_name: "Steve",
            last_name:  "Evets",
            email:      employee.email,
          }.to_json,
          headers: {authorization: "Bearer #{user.jwt_token}"},
          content_type: "application/json"
        )

        response.status.should eq 422
        response.content.should eq({
          error: {
            messages: ["Email: Already taken."],
          },
        }.to_json)

        Workaty::Employee.filter(email: employee.email).count.should eq 1
      end
    end
  end
end
