# Shared IAM concern for mapping local users to a stable IAM identifier and
# creating/updating users from IAM-provided profile data. Any deployment can
# act as the federation source ("IAM") for others; there's nothing here tied
# to a specific app.
#
# generate_iam_identifier! is deliberately never called on every save. A user
# who never federated has a nil iam_identifier_primary, which keeps the first
# webhook bind by email working; auto-assigning one on every save would make
# every ordinary local signup look like an existing, conflicting federation
# identity the first time a real IAM webhook tries to bind that email.
module IamIdentifiable
  record UserInfo,
    given_name : String,
    family_name : String?,
    email : String,
    role : Int32 | Int64 do
    include JSON::Serializable
  end

  macro included
    def self.find_or_create_by_iam_identifier(
      iam_identifier_primary : String,
      user_info : UserInfo,
    )
      # look up by canonical identifier first
      if existing_user = self.filter(iam_identifier_primary: iam_identifier_primary).first?
        return existing_user
      end

      # fallback: existing local user whose email matches
      if user_info.email.presence && (existing_user = self.filter(email__iexact: user_info.email).first?)
        matches = Crypto::Subtle.constant_time_compare(
          existing_user.iam_identifier_primary.presence || "",
          iam_identifier_primary.presence || ""
        )

        if existing_user.iam_identifier_primary.presence && !matches
          raise ArgumentError.new("iam_identifier_primary mismatch for existing user")
        end

        unless matches
          existing_user.iam_identifier_primary = iam_identifier_primary
          existing_user.save!
        end

        return existing_user
      end

      # new user arriving from another realm for the first time
      user = self.new(
        email: user_info.email,
        first_name: user_info.given_name,
        last_name: user_info.family_name,
        role: user_info.role,
        iam_identifier_primary: iam_identifier_primary,
        password_updated_at: Time.utc
      )

      user.set_unusable_password
      user.save!

      user
    end
  end

  def ensure_iam_identifier!
    generate_iam_identifier!
    save! if persisted?
  end

  def generate_iam_identifier!
    return if iam_identifier_primary.presence
    self.iam_identifier_primary = UUID.random.to_s
  end
end
