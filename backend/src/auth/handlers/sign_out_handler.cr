require "./concerns/*"

module Auth
  class SignOutHandler < Marten::Handler
    include RequireSignedInUser

    http_method_names :post, :options

    def post
      MartenAuth.sign_out(request)
      redirect reverse("auth:sign_in")
    end
  end
end
