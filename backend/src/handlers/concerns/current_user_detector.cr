module CurrentUserDetector
  protected def current_user : Auth::User | Nil
    request.current_user
  end

  protected def current_user! : Auth::User
    current_user.not_nil!
  end

  protected def current_organization! : Auth::Organization
    current_user!.organization.not_nil!
  end
end
