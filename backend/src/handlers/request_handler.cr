class RequestHandler < Marten::Handler
  include CurrentUserDetector
  include HandlerResponders

  before_dispatch :set_locale

  protected def set_locale
    return unless current_user
    I18n.activate(current_user.not_nil!.locale!)
  end
end
