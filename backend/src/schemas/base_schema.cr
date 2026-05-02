class BaseSchema < Marten::Schema
  include SchemaDefiner

  property :user

  @user : Auth::User?

  alias AnyDataHash = Marten::Schema::AnyDataHash

  def initialize(data : AnyDataHash)
    super(data)
  end

  def initialize(data : AnyDataHash, initial : AnyDataHash)
    super(data, initial)
  end

  def initialize(data : AnyDataHash, user : Auth::User)
    @user = user
    super(data)
  end

  def initialize(data : AnyDataHash, initial : AnyDataHash, user : Auth::User)
    @user = user
    super(data, initial)
  end

  private def current_user!
    @user.not_nil!
  end

  private def current_organization!
    current_user.organization
  end
end
