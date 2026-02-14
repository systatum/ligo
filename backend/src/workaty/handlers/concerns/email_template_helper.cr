module Workaty::EmailTemplateHelper
  @email_template : Workaty::EmailTemplate?

  def authorize_email_template_manipulation_request!
    raise Auth::AuthorizationError.new unless current_user

    role_name = Workaty::RoleMapper.map_user_role_to_rbacr(current_user.not_nil!)

    can = can?(Auth::Authorizer::CAN_MANAGE_EMAIL_TEMPLATE, role_name)
    raise Auth::AuthorizationError.new unless can
  end

  private def validate_email_template_params!(form : FormPayload) : Hash(String, String) | Nil
    errors = {} of String => String

    title = form.native_fields["title"]?
    if title.nil? || title.to_s.strip.empty?
      errors["title"] = "Title is required"
    end

    content = form.native_fields["content"]?
    if content.nil? || content.to_s.strip.empty?
      errors["content"] = "Content is required"
    end

    return errors unless errors.empty?
    nil
  end

  private def email_template
    @email_template ||= Workaty::EmailTemplate
      .filter_by_hashed_id(params["template_hashed_id"].to_s)
      .get!(organization_id: current_user!.organization_id)
  end
end
