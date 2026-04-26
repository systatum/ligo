module Antrikan
  class Queuer < Marten::Model
    include ChangeTracker
    include SoftDeleter
    include IdConcealer

    field :id, :big_int, primary_key: true, auto: true
    field :space, :many_to_one, to: Antrikan::Space, related: :queuers
    field :user, :many_to_one, to: Auth::User, related: :queuers, null: true, blank: true
    field :name, :string, max_size: 255, null: false, blank: false
    field :password_hash, :string, max_size: 255, null: false, blank: false
    field :created_at, :date_time, null: false, auto_now_add: true
    field :updated_at, :date_time, null: false, auto_now: true

    def password=(plain : String)
      self.password_hash = Crypto::Bcrypt::Password.create(plain, cost: 12).to_s
    end

    def password_matches?(plain : String) : Bool
      Crypto::Bcrypt::Password.new(password_hash!).verify(plain)
    end
  end
end
