module Auth
  class AuthorizationError < Marten::HTTP::Errors::PermissionDenied
  end
end
