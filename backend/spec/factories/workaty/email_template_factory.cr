def create_email_template(
  adder : Auth::User = create_user,
  title : String = "Test Template",
  content : String = "<p>Test content</p>",
)
  template = Workaty::EmailTemplate.new
  template.organization = adder.organization!
  template.title = title
  template.content = content
  template.save!

  template
end
