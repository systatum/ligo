class Workaty::EmailTemplateDeleteHandler < RequestHandler
  include Workaty::EmailTemplateHelper

  protect_from_forgery false
  http_method_names :delete

  def delete : Marten::HTTP::Response
    authorize_email_template_manipulation_request!

    email_template.soft_delete!

    Marten::HTTP::Response.new(content: "", status: 204)
  end
end
