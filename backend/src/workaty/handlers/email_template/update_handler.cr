class Workaty::EmailTemplateUpdateHandler < RequestHandler
  include Workaty::EmailTemplateHelper

  protect_from_forgery false
  http_method_names :patch, :post

  def post : Marten::HTTP::Response
    patch
  end

  def patch : Marten::HTTP::Response
    authorize_email_template_manipulation_request!

    form = FormPayload.new(request.body)

    if errors = validate_email_template_params!(form)
      return json({"errors" => errors}, status: 400)
    end

    email_template.title = form.native_fields["title"].to_s
    email_template.content = form.native_fields["content"].to_s
    email_template.save!

    FieldValue.update!(email_template, form, FieldResourceType::EMAIL_TEMPLATE)

    json Workaty::EmailTemplateSerializer.serialize_with_fields(
      email_template,
      FieldResourceType::EMAIL_TEMPLATE
    ), status: 200
  end
end
