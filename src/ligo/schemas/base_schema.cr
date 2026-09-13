class BaseSchema < Marten::Schema
  # include SchemaDefiner

  property :user

  @user : Ligo::User?

  alias AnyDataHash = Marten::Schema::AnyDataHash

  def initialize(data : AnyDataHash)
    super(data)
  end

  def initialize(data : AnyDataHash, initial : AnyDataHash)
    super(data, initial)
  end

  def initialize(data : AnyDataHash, user : Ligo::User)
    @user = user
    super(data)
  end

  def initialize(data : AnyDataHash, initial : AnyDataHash, user : Ligo::User)
    @user = user
    super(data, initial)
  end

  private def current_user!
    @user.not_nil!
  end

  private def current_organization!
    current_user.organization
  end

  # Shared cap check for any `:array` schema field holding upload/keep-id
  # entries.
  private def validate_max_images(field_name : Symbol, images, max : Int32)
    return unless images
    return if images.size <= max

    errors.add(field_name, "cannot have more than #{max} images")
  end
end
