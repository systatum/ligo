module Antrikan
  # Truncates the entire database, then seeds baseline Antrikan data for E2E
  # testing. Destructive - refuses to run in production.
  class Seed < Marten::CLI::Command
    help "Truncate the database and seed baseline Antrikan E2E data (destructive, non-production only)"

    DEV_USER_EMAIL    = "e2e-dev@example.com"
    DEV_USER_PASSWORD = "Password01"

    def run
      unless Marten.env.development?
        stderr.puts "Refusing to run outside development - this command truncates the entire database."
        exit(1)
      end

      flush_database!
      seed!
    end

    private def flush_database!
      stdout.puts "Truncating all tables..."

      Marten::DB::Connection.registry.values.each do |conn|
        Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
          schema_editor.flush_model_tables
        end
      end
    end

    private def seed!
      organization = Auth::Organization.new(name: "Berburgeran Indonesia")
      organization.save!

      user = Auth::User.new(
        organization: organization,
        email: DEV_USER_EMAIL,
        role: Auth::Role::OWNER,
        first_name: "Berburgeran",
        last_name: "Admin",
        iam_identifier_primary: "e2e-dev-user",
      )
      user.set_password(DEV_USER_PASSWORD)
      user.save!

      business = Business.create!(name: "Berburgeran Indonesia", owner: user)

      space = Space.new(name: "Berburgeran Bogor")
      space.manager = user
      space.owner = business
      space.save!

      channel = Channel.new(space: space, name: "Burger")
      channel.save!

      item_a = Item.new(channel: channel, name: "Classic Cheeseburger", unit_price: 35_000_i64)
      item_a.save!

      item_b = Item.new(channel: channel, name: "Double Beef Burger", unit_price: 55_000_i64)
      item_b.save!

      voucher = Voucher.new(space: space, channel: channel, code: "CHANNELWIDE", channel_percentage_discount: 10.0)
      voucher.save!

      stdout.puts "Seeded space '#{space.name!}' (code: #{space.code!}) under business '#{business.name!}'."
      stdout.puts "Seeded channel '#{channel.name!}' with items '#{item_a.name!}' and '#{item_b.name!}'."
      stdout.puts "Seeded voucher '#{voucher.code!}' - #{voucher.channel_percentage_discount!}% off '#{channel.name!}'."
      stdout.puts "Dev user: #{DEV_USER_EMAIL} / #{DEV_USER_PASSWORD}"
    end
  end
end
