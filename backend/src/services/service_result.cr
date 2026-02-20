struct ServiceResult(T)
  alias ErrorType = Marten::Core::Validation::ErrorSet

  getter data : T?
  getter errors : ErrorType?

  def initialize(@success : Bool, @data : T? = nil, @errors : ErrorType? = nil)
  end

  def failure? : Bool
    !@success
  end

  def success? : Bool
    @success
  end

  def self.success(data : T) : ServiceResult(T)
    new(success: true, data: data)
  end

  def self.failure(errors : ErrorType? = nil) : ServiceResult(T)
    new(success: false, errors: errors)
  end
end
