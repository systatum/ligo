class RequestHandler < Marten::Handler
  include CurrentUserDetector
  include HandlerResponders
end
