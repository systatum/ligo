class Workaty::EmailTemplateShowHandler < RequestHandler
  include Workaty::EmailTemplateHelper

  protect_from_forgery false
  http_method_names :get

  def get : Marten::HTTP::Response
    authorize_email_template_manipulation_request!

    json Workaty::EmailTemplateSerializer.serialize_with_fields(
      email_template,
      FieldResourceType::EMAIL_TEMPLATE
    ), status: 200
  end
end
