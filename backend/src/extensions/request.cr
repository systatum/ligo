class Marten::HTTP::Request
  @current_user : Auth::User | Nil

  def current_user : Auth::User | Nil
    @current_user
  end

  def current_user! : Auth::User
    current_user.not_nil!
  end

  def current_user=(user : Auth::User | Nil)
    @current_user = user
  end
end
