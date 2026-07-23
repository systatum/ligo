# Whenever we introduce a service object subclassing this:
# It must end with erService, in this way precisely: {Proper Noun?}{Verb}erService
abstract class BaseService(T)
  abstract def run : ServiceResult(T)

  protected def success(data : T) : ServiceResult(T) forall T
    ServiceResult(T).success(data)
  end

  protected def failure(errors : ServiceResult::ErrorType? = nil) : ServiceResult(T)
    ServiceResult(T).failure(errors)
  end

  protected def failure(field : String | Symbol, message : String) : ServiceResult(T)
    errors = ServiceResult::ErrorType.new
    errors.add(field, message)
    ServiceResult(T).failure(errors)
  end

  protected def failure(message : String) : ServiceResult(T)
    errors = ServiceResult::ErrorType.new
    errors.add(message)
    ServiceResult(T).failure(errors)
  end

  # may bundle errors from more than one failed step.
  class TransactionError < Exception
    getter errors : ServiceResult::ErrorType?

    def initialize(@errors : ServiceResult::ErrorType?)
      super()
    end
  end
end
