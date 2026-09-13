module CurrentUserDetector
  protected def current_user : Ligo::User | Nil
    request.current_user
  end

  protected def current_user! : Ligo::User
    current_user.not_nil!
  end

  protected def current_organization! : Ligo::Organization
    current_user!.organization.not_nil!
  end
end
