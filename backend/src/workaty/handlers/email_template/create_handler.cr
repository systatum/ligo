class Workaty::EmailTemplateCreateHandler < RequestHandler
  include Workaty::EmailTemplateHelper

  protect_from_forgery false
  http_method_names :post

  def post : Marten::HTTP::Response
    authorize_email_template_manipulation_request!

    form = FormPayload.new(request.body)

    if errors = validate_email_template_params!(form)
      return json({"errors" => errors}, status: 400)
    end

    template = Workaty::EmailTemplate.new
    template.organization = current_user!.organization
    template.title = form.native_fields["title"].to_s
    template.content = form.native_fields["content"].to_s
    template.save!

    FieldValue.update!(template, form, FieldResourceType::EMAIL_TEMPLATE)

    json Workaty::EmailTemplateSerializer.serialize_with_fields(
      template,
      FieldResourceType::EMAIL_TEMPLATE
    ), status: 200
  end
end
