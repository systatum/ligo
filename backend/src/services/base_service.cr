# Whenever we introduce a service object subclassing this:
# It must end with erService, in this way precisely: {Proper Noun?}{Verb}erService
abstract class BaseService
  abstract def run : ServiceResult
end
