module Errors
  class ServiceException < Exception
    getter errors : ServiceResult::ErrorType?

    def initialize(@errors : ServiceResult::ErrorType? = nil)
    end

    def initialize(field : String | Symbol, message : String)
      e = ServiceResult::ErrorType.new
      e.add(field, message)
      @errors = e
    end

    def initialize(message : String)
      e = ServiceResult::ErrorType.new
      e.add(message)
      @errors = e
    end
  end

  class LogoUploadException < ServiceException
  end
end
