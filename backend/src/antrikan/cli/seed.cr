module Antrikan
  # Truncates the entire database, then seeds baseline Antrikan data for E2E
  # testing. Destructive - refuses to run in production.
  class Seed < Marten::CLI::Command
    include FileUploader

    help "Truncate the database and seed baseline Antrikan E2E data (destructive, non-production only)"

    DEV_USER_EMAIL          = "e2e-dev@example.com"
    DEV_USER_PASSWORD       = "Password01"
    TEST_OWNER_PASSWORD     = "Password01"
    BURGER_TEST_OWNER_EMAIL = "burger@test.com"
    CUSTOMER_EMAIL          = "e2e-customer@example.com"
    CUSTOMER_PASSWORD       = "Password01"
    BOGOR_CITY_CODE         = 100160007 # data/countries/100_IDN.json - Bogor, West Java

    HOSPITAL_ADMIN_EMAIL      = "e2e-hospital-admin@example.com"
    HOSPITAL_ADMIN_PASSWORD   = "Password01"
    HOSPITAL_TEST_OWNER_EMAIL = "hospital@test.com"
    SURABAYA_CITY_CODE        = 100140065 # data/countries/100_IDN.json - Surabaya, East Java

    BURGER_CAROUSEL_IMAGE_FILES = %w(
      data/seed_images/black_700x250.png
      data/seed_images/green_700x250.png
      data/seed_images/blue_700x250.png
    )
    HOSPITAL_CAROUSEL_IMAGE_FILES = %w(
      data/seed_images/maroon_700x250.png
      data/seed_images/green_700x250.png
    )

    def run
      unless Marten.env.development?
        stderr.puts "Refusing to run outside development - this command truncates the entire database."
        exit(1)
      end

      flush_database!
      seed_realms!
      seed_burger_shop!
      seed_hospital!
    end

    private def seed_realms!
      result = DefaultRealmsSeeder.seed!
      stdout.puts "Seeded realms: #{result[:created]} created, #{result[:skipped]} already existed."
    end

    private def flush_database!
      stdout.puts "Truncating all tables..."

      Marten::DB::Connection.registry.values.each do |conn|
        Marten::DB::Management::SchemaEditor.run_for(conn) do |schema_editor|
          schema_editor.flush_model_tables
        end
      end
    end

    private def seed_burger_shop!
      organization = Auth::Organization.new(name: "Berburgeran Indonesia")
      organization.save!

      seed_email_verified_owner!(organization, BURGER_TEST_OWNER_EMAIL)

      user = Auth::User.new(
        organization: organization,
        email: DEV_USER_EMAIL,
        role: Auth::Role::OWNER,
        first_name: "Berburgeran",
        last_name: "Admin",
        iam_identifier_primary: "e2e-dev-user",
        is_email_address_verified: true,
      )
      user.set_password(DEV_USER_PASSWORD)
      user.save!

      customer = Auth::User.new(
        email: CUSTOMER_EMAIL,
        role: Auth::Role::CUSTOMER,
        first_name: "Budi",
        last_name: "Santoso",
        iam_identifier_primary: "e2e-customer-user",
        is_email_address_verified: true,
      )
      customer.set_password(CUSTOMER_PASSWORD)
      customer.save!

      business = Business.create!(name: "Berburgeran Indonesia", owner: user)

      space = Space.new(name: "Berburgeran Bogor", code: "RUJVJ")
      space.manager = user
      space.owner = business
      space.description = "Homestyle smash burgers, grilled fresh to order."
      space.address = "Jl. Pajajaran No. 21"
      space.address_city_code = BOGOR_CITY_CODE
      space.address_postal_code = "16143"
      space.latitude = -6.5971
      space.longitude = 106.8060
      space.phone = "0251-1234567"
      space.email = "hello@berburgeran.example.com"
      space.has_operating_hours = true
      space.save!

      seed_carousel_images!(space, user, BURGER_CAROUSEL_IMAGE_FILES)

      channel = Channel.new(space: space, name: "Burger")
      channel.description = "All burgers, made fresh on order."
      channel.enforce_operating_hours = true
      channel.save!

      item_a = Item.new(channel: channel, name: "Classic Cheeseburger", unit_price: 35_000_i64)
      item_a.description = "Beef patty, cheddar, lettuce, tomato, house sauce."
      item_a.daily_cap = 50
      item_a.save!

      item_b = Item.new(channel: channel, name: "Double Beef Burger", unit_price: 55_000_i64)
      item_b.description = "Two beef patties, double cheddar, caramelized onions."
      item_b.daily_cap = 30
      item_b.save!

      hotdog_channel = Channel.new(space: space, name: "Hotdog")
      hotdog_channel.enforce_operating_hours = false
      hotdog_channel.save!

      item_c = Item.new(channel: hotdog_channel, name: "Cheese Hotdog", unit_price: 45_000_i64)
      item_c.description = "Classic hotdogs, grilled fresh to order."
      item_c.daily_cap = 150
      item_c.save!

      seed_operating_hours!(space, open_hour: 9, close_hour: 21, saturday_open_hour: 10, saturday_close_hour: 22)

      voucher = Voucher.new(space: space, channel: channel, code: "CHANNELWIDE", channel_percentage_discount: 10.0)
      voucher.save!

      review = SpaceReview.new(
        space: space,
        reviewer: customer,
        rating: 9.0,
        review: "Best smash burger in Bogor, generous portion and fast service!",
      )
      review.save!

      stdout.puts "Seeded space '#{space.name!}' (code: #{space.code!}) under business '#{business.name!}'."
      stdout.puts "Seeded #{space.carousel_image_ids!.ids.size} carousel images for '#{space.name!}'."
      stdout.puts "Seeded channel '#{channel.name!}' (id: #{channel.hashed_id}) with items '#{item_a.name!}' and '#{item_b.name!}'."
      stdout.puts "Seeded channel '#{hotdog_channel.name!}' (id: #{hotdog_channel.hashed_id}, enforce_operating_hours: false) with item '#{item_c.name!}'."
      stdout.puts "Seeded operating hours Mon-Sat for '#{space.name!}' (closed Sunday - no entry seeded for that day)."
      stdout.puts "Seeded voucher '#{voucher.code!}' - #{voucher.channel_percentage_discount!}% off '#{channel.name!}'."
      stdout.puts "Seeded a review from '#{customer.email!}' (rating: #{review.rating!})."
      stdout.puts "Dev user: #{DEV_USER_EMAIL} / #{DEV_USER_PASSWORD}"
      stdout.puts "Customer user: #{CUSTOMER_EMAIL} / #{CUSTOMER_PASSWORD}"
      stdout.puts "Test owner user (email-verified): #{BURGER_TEST_OWNER_EMAIL} / #{TEST_OWNER_PASSWORD}"
    end

    private def seed_hospital!
      organization = Auth::Organization.new(name: "Yayasan Harapan Bunda")
      organization.save!

      seed_email_verified_owner!(organization, HOSPITAL_TEST_OWNER_EMAIL)

      admin = Auth::User.new(
        organization: organization,
        email: HOSPITAL_ADMIN_EMAIL,
        role: Auth::Role::OWNER,
        first_name: "Harapan Bunda",
        last_name: "Admin",
        iam_identifier_primary: "e2e-hospital-admin-user",
        is_email_address_verified: true,
      )
      admin.set_password(HOSPITAL_ADMIN_PASSWORD)
      admin.save!

      business = Business.create!(name: "Yayasan Harapan Bunda", owner: admin)

      space = Space.new(name: "Rumah Sakit Harapan Bunda", code: "HRPBN")
      space.manager = admin
      space.owner = business
      space.description = "General hospital serving Surabaya and the surrounding area."
      space.address = "Jl. Raya Darmo No. 90"
      space.address_city_code = SURABAYA_CITY_CODE
      space.address_postal_code = "60241"
      space.latitude = -7.2909
      space.longitude = 112.7381
      space.phone = "031-5671234"
      space.email = "info@harapanbunda.example.com"
      space.save!

      seed_carousel_images!(space, admin, HOSPITAL_CAROUSEL_IMAGE_FILES)
      seed_operating_hours!(space, open_hour: 10, close_hour: 17)

      orthodontics = seed_hospital_channel!(space, "Orthodontics", max_item_piece: 1)
      orthodontists = seed_hospital_doctors!(orthodontics, ["Dr. Siti Rahayu, Sp.Ort", "Dr. Bambang Wijaya, Sp.Ort", "Dr. Andi Prasetyo, Sp.Ort"])
      seed_orthodontist_hours!(orthodontists)

      internal_medicine = seed_hospital_channel!(space, "Internal Medicine", max_item_piece: 1)
      seed_hospital_doctors!(internal_medicine, ["Dr. Ratna Kusumawati, Sp.PD", "Dr. Hendra Setiawan, Sp.PD"])

      pediatrics = seed_hospital_channel!(space, "Pediatrics", max_item_piece: 1)
      seed_hospital_doctors!(pediatrics, ["Dr. Maya Kusuma, Sp.A", "Dr. Rudi Hartono, Sp.A"])

      cardiology = seed_hospital_channel!(space, "Cardiology", max_item_piece: 1)
      seed_hospital_doctors!(cardiology, ["Dr. Fajar Nugroho, Sp.JP", "Dr. Linda Susanti, Sp.JP"])
      seed_cardiology_hours!(cardiology)

      checkup = seed_hospital_channel!(space, "Checkup", max_item_piece: -1)
      checkup_items = seed_checkup_packages!(checkup)

      item_voucher = Voucher.new(space: space, code: "CHECKUPDEAL")
      item_voucher.discountable_items = DiscountableItems.new(entries: [
        discountable_item_entry(checkup_items[0].slug!, 10.0),
        discountable_item_entry(checkup_items[1].slug!, 15.0),
      ])
      item_voucher.save!

      channel_voucher = Voucher.new(space: space, channel: orthodontics, code: "ORTHOOFF", channel_percentage_discount: 15.0)
      channel_voucher.save!

      space_voucher = Voucher.new(space: space, code: "HOSPITALWIDE", space_percentage_discount: 5.0)
      space_voucher.save!

      stdout.puts "Seeded space '#{space.name!}' (code: #{space.code!}) under business '#{business.name!}'."
      stdout.puts "Seeded #{space.carousel_image_ids!.ids.size} carousel images for '#{space.name!}'."
      stdout.puts "Seeded channels: #{[orthodontics, internal_medicine, pediatrics, cardiology, checkup].map { |c| "#{c.name!} (id: #{c.hashed_id})" }.join(", ")}."
      stdout.puts "Seeded hospital-wide operating hours 10AM-5PM Mon-Sat for '#{space.name!}'."
      stdout.puts "Seeded #{orthodontists.size} non-overlapping per-doctor hours for '#{orthodontics.name!}' (no channel-level hours - only per-doctor)."
      stdout.puts "Seeded '#{cardiology.name!}' hours: Mon 11AM-3PM, Wed & Fri 2:00PM-4:30PM only."
      stdout.puts "Seeded #{checkup_items.size} checkup packages under '#{checkup.name!}'."
      stdout.puts "Seeded vouchers '#{item_voucher.code!}' (item-specific), '#{channel_voucher.code!}' (channel-wide), '#{space_voucher.code!}' (space-wide)."
      stdout.puts "Hospital admin user: #{HOSPITAL_ADMIN_EMAIL} / #{HOSPITAL_ADMIN_PASSWORD}"
      stdout.puts "Test owner user (email-verified): #{HOSPITAL_TEST_OWNER_EMAIL} / #{TEST_OWNER_PASSWORD}"
    end

    private def seed_email_verified_owner!(organization : Auth::Organization, email : String) : Auth::User
      user = Auth::User.new(
        organization: organization,
        email: email,
        role: Auth::Role::OWNER,
        first_name: "Test",
        last_name: "Owner",
        iam_identifier_primary: "test-owner-#{email}",
      )
      user.set_password(TEST_OWNER_PASSWORD)
      user.is_email_address_verified = true
      user.save!

      user
    end

    private def seed_hospital_channel!(space : Space, name : String, max_item_piece : Int32) : Channel
      channel = Channel.new(space: space, name: name)
      channel.max_item_piece = max_item_piece
      channel.save!
      channel
    end

    private def seed_hospital_doctors!(channel : Channel, doctor_names : Array(String)) : Array(Item)
      doctor_names.map do |doctor_name|
        item = Item.new(channel: channel, name: doctor_name, unit_price: 150_000_i64)
        item.description = "Consultation slot with #{doctor_name}."
        item.daily_cap = 20
        item.save!
        item
      end
    end

    # Each doctor gets their own non-overlapping slot, Monday-Saturday. No
    # channel-level operating hour for Orthodontics itself - only per-doctor.
    private def seed_orthodontist_hours!(doctors : Array(Item))
      slots = [
        {8, 11},  # 08:00-11:00
        {11, 14}, # 11:00-14:00
        {14, 17}, # 14:00-17:00
      ]

      doctors.each_with_index do |doctor, index|
        open_hour, close_hour = slots[index]

        (0..5).each do |day|
          op_hour = OperatingHour.new(
            item: doctor,
            day: day,
            open_time: Time::Span.new(hours: open_hour, minutes: 0),
            close_time: Time::Span.new(hours: close_hour, minutes: 0)
          )
          op_hour.save!
        end
      end
    end

    # Cardiology only runs Monday (11AM-3PM), and Wednesday/Friday (2PM-4:30PM).
    private def seed_cardiology_hours!(channel : Channel)
      schedule = {
        OperatingHour::Day::MONDAY.value    => {11, 0, 15, 0},
        OperatingHour::Day::WEDNESDAY.value => {14, 0, 16, 30},
        OperatingHour::Day::FRIDAY.value    => {14, 0, 16, 30},
      }

      schedule.each do |day, (open_hour, open_minute, close_hour, close_minute)|
        op_hour = OperatingHour.new(
          channel: channel,
          day: day,
          open_time: Time::Span.new(hours: open_hour, minutes: open_minute),
          close_time: Time::Span.new(hours: close_hour, minutes: close_minute)
        )
        op_hour.save!
      end
    end

    private def seed_checkup_packages!(channel : Channel) : Array(Item)
      packages = [
        {"Simple Basic", 350_000_i64, "Basic blood work, blood pressure, and BMI check."},
        {"Healthy Gamer", 750_000_i64, "Eye strain, posture, and cardiovascular screening for long screen-time habits."},
        {"Executive Premium", 2_500_000_i64, "Comprehensive panel: blood work, ECG, chest X-ray, and abdominal ultrasound."},
        {"Heart Health Plus", 1_200_000_i64, "ECG, cholesterol panel, and cardiologist consultation."},
        {"Diabetes Screening", 450_000_i64, "Fasting blood glucose, HbA1c, and dietitian consultation."},
        {"Women's Wellness", 900_000_i64, "Pap smear, breast exam, and hormone panel."},
        {"Senior Complete", 1_800_000_i64, "Bone density, cognitive screening, and cardiovascular check."},
      ]

      packages.map do |(name, price, description)|
        item = Item.new(channel: channel, name: name, unit_price: price)
        item.description = description
        item.daily_cap = 15
        item.save!
        item
      end
    end

    private def discountable_item_entry(item_slug : String, percentage_discount : Float64) : DiscountableItems::Entry
      DiscountableItems::Entry.from_json({
        item_id:             item_slug,
        percentage_discount: percentage_discount,
        mode:                "override",
      }.to_json)
    end

    private def seed_carousel_images!(space : Space, uploaded_by : Auth::User, files : Array(String))
      ids = files.compact_map do |path|
        payload = FilePayload.from_json({base64_bytes: Base64.encode(File.read(path)), mimetype: "image/png"}.to_json)
        upload_image(payload, uploaded_by).try(&.to_s)
      end

      space.carousel_image_ids = UploadedFileIds.new(ids: ids)
      space.save!
    end

    # Open Monday(0) through Saturday(5); Sunday(6) intentionally has no entry,
    # representing a closed day - see OperatingHour#open_at? fallback behavior.
    # Saturday can optionally use its own hours; otherwise it matches the rest of the week.
    private def seed_operating_hours!(
      space : Space,
      open_hour : Int32,
      close_hour : Int32,
      saturday_open_hour : Int32? = nil,
      saturday_close_hour : Int32? = nil,
    )
      (0..5).each do |day|
        is_saturday = day == 5
        day_open_hour = is_saturday ? (saturday_open_hour || open_hour) : open_hour
        day_close_hour = is_saturday ? (saturday_close_hour || close_hour) : close_hour

        op_hour = OperatingHour.new(
          space: space,
          day: day,
          open_time: Time::Span.new(hours: day_open_hour, minutes: 0),
          close_time: Time::Span.new(hours: day_close_hour, minutes: 0)
        )
        op_hour.save!
      end
    end
  end
end
