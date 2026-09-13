class Marten::HTTP::Request
  @current_user : Ligo::User | Nil

  def current_user : Ligo::User | Nil
    @current_user
  end

  def current_user! : Ligo::User
    current_user.not_nil!
  end

  def current_user=(user : Ligo::User | Nil)
    @current_user = user
  end
end
