module Auth
  module IamOnly
    macro included
      before_dispatch :require_iam_mode

      private def require_iam_mode
        head 404 unless AppSettings.app_mode == "iam"
      end
    end
  end
end
