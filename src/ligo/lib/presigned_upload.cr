module PresignedUpload
  # Called before a presigned upload URL is issued, with the requesting account and its declared
  # byte size. Raises to reject the upload; otherwise returns the expiry to set on the resulting
  # UploadedFile row, or nil for a permanent upload. Defaults to no expiry.
  alias AuthorizeHook = Proc(Ligo::User, Int64, Time?)

  @@authorize_hook : AuthorizeHook = ->(account : Ligo::User, declared_size : Int64) { nil.as(Time?) }

  def self.authorize_hook=(hook : AuthorizeHook)
    @@authorize_hook = hook
  end

  def self.authorize_hook : AuthorizeHook
    @@authorize_hook
  end
end
