class Workaty::EmailTemplateIndexHandler < RequestHandler
  include Workaty::EmailTemplateHelper

  protect_from_forgery false
  http_method_names :get

  def get : Marten::HTTP::Response
    authorize_email_template_manipulation_request!

    templates = Workaty::EmailTemplate.filter(
      organization: current_user!.organization
    ).to_a

    json Workaty::EmailTemplateSerializer.serialize_with_fields(
      templates,
      FieldResourceType::EMAIL_TEMPLATE
    ), status: 200
  end
end
