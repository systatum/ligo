require "./space_factory"

def create_voucher(
  space : Antrikan::Space = create_space,
  channel : Antrikan::Channel? = nil,
  code : String? = nil,
  name : String? = nil,
  space_percentage_discount : Float64? = nil,
  space_fixed_discount : Int64? = nil,
  channel_percentage_discount : Float64? = nil,
  channel_fixed_discount : Int64? = nil,
  discountable_items : Antrikan::DiscountableItems? = nil,
  indeterminate : Bool = true,
  starts_at : Time? = nil,
  expires_at : Time? = nil,
  anon_redeemable : Bool = true,
  max_redeem_per_user : Int32 = -1,
) : Antrikan::Voucher
  voucher = Antrikan::Voucher.new
  voucher.space = space
  voucher.channel = channel
  voucher.code = code if code
  voucher.name = name
  voucher.space_percentage_discount = space_percentage_discount
  voucher.space_fixed_discount = space_fixed_discount
  voucher.channel_percentage_discount = channel_percentage_discount
  voucher.channel_fixed_discount = channel_fixed_discount
  voucher.discountable_items = discountable_items
  voucher.indeterminate = indeterminate
  voucher.starts_at = starts_at
  voucher.expires_at = expires_at
  voucher.anon_redeemable = anon_redeemable
  voucher.max_redeem_per_user = max_redeem_per_user
  voucher.save!

  voucher
end
