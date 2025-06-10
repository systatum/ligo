require "../../spec_helper"

describe Workaty::EmployeeIndexHandler do
  describe "#get" do
    it "lists all the employees belonging to the organization of the user" do
      user = create_user
      other_user = create_user
      team_div1 = create_team_division(adder: user, name: "Team Division 1")
      team_div2 = create_team_division(adder: user, name: "Team Division 2")
      employee1 = create_employee(adder: user, team_division: team_div1)
      employee2 = create_employee(adder: user, team_division: team_div2)
      employee3 = create_employee(adder: user, team_division: team_div2)
      other_org_employee1 = create_employee(adder: other_user)
      other_org_employee2 = create_employee(adder: other_user)

      # ensure there's no leader yet -- needed because the changetracker logic may alter the count
      team_div1.leaders.count.should eq 0
      team_div2.leaders.count.should eq 0

      # add leaders to team divisions
      team_div1.add_leaders(employee1)
      team_div2.add_leaders(employee2)
      team_div1.leaders.to_a.should eq [employee1]
      team_div2.leaders.to_a.should eq [employee2]

      # test changelogs
      employee1_changelogs = Changelog.filter(record_class: "Workaty::Employee", record_id: employee1.id)
      employee1_changelogs.count.should eq 2
      employee1_changelogs.last.not_nil!.changes!["team_divisions"].should eq({
        "type"          => "ref_m2m",
        "current_value" => "[#{team_div1.id}]",
        "old_value"     => "[]",
      })

      response = Marten::Spec.client.get(
        Marten.routes.reverse("workaty:employee:index"),
        headers: {authorization: "Bearer #{user.jwt_token}"},
        content_type: "application/json"
      )

      response.status.should eq 200

      org = user.organization!
      employees = Workaty::Employee.filter(organization: org).map do |employee|
        Workaty::EmployeeSerializer.soft_serialize(employee)
      end

      team_divisions = Workaty::TeamDivision.filter(organization: org).map do |team_division|
        Workaty::TeamDivisionSerializer.soft_serialize(team_division)
      end

      json_response = JSON.parse(response.content)
      response.content.should eq({
        employees:      employees,
        team_divisions: team_divisions,
      }.to_json)
    end
  end
end
