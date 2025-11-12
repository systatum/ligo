# Define all your system fields here

# This file is loaded automatically and defines all system fields
# that should be created/updated in the database

module SystemFields
  def self.load_defaults
    # ===== CANDIDATE FIELDS =====

    SystemFieldsMigrator.add_string_field!(
      "first_name",
      to: FieldResourceType::CANDIDATE,
      localized_name: LocalizedName.new(
        english: "First Name",
        indonesian: "Nama Depan",
        japanese: "名"
      ),
      nullable: false
    )

    SystemFieldsMigrator.add_string_field!(
      "last_name",
      to: FieldResourceType::CANDIDATE,
      localized_name: LocalizedName.new(
        english: "Last Name",
        indonesian: "Nama Belakang",
        japanese: "姓"
      ),
      nullable: true
    )

    SystemFieldsMigrator.add_string_field!(
      "email",
      to: FieldResourceType::CANDIDATE,
      localized_name: LocalizedName.new(
        english: "Email Address",
        indonesian: "Alamat Email",
        japanese: "メールアドレス"
      ),
      nullable: true
    )

    SystemFieldsMigrator.add_string_field!(
      "phone",
      to: FieldResourceType::CANDIDATE,
      localized_name: LocalizedName.new(
        english: "Phone Number",
        indonesian: "Nomor Telepon",
        japanese: "電話番号"
      ),
      nullable: true
    )

    SystemFieldsMigrator.add_string_field!(
      "note",
      to: FieldResourceType::CANDIDATE,
      localized_name: LocalizedName.new(
        english: "Note",
        indonesian: "Catatan",
        japanese: "メモ"
      ),
      nullable: true
    )

    SystemFieldsMigrator.add_string_field!(
      "fitness",
      to: FieldResourceType::CANDIDATE,
      localized_name: LocalizedName.new(
        english: "Fitness Status",
        indonesian: "Status Kebugaran",
        japanese: "フィットネスステータス"
      ),
      nullable: false
    )

    # ===== USER FIELDS =====

    SystemFieldsMigrator.add_string_field!(
      "first_name",
      to: FieldResourceType::USER,
      localized_name: LocalizedName.new(
        english: "First Name",
        indonesian: "Nama Depan",
        japanese: "名"
      ),
      nullable: false
    )

    SystemFieldsMigrator.add_string_field!(
      "last_name",
      to: FieldResourceType::USER,
      localized_name: LocalizedName.new(
        english: "Last Name",
        indonesian: "Nama Belakang",
        japanese: "姓"
      ),
      nullable: true
    )

    SystemFieldsMigrator.add_string_field!(
      "email",
      to: FieldResourceType::USER,
      localized_name: LocalizedName.new(
        english: "Email Address",
        indonesian: "Alamat Email",
        japanese: "メールアドレス"
      ),
      nullable: false,
      uniqueness: FieldUniqueness::UNIQUE_ALWAYS
    )

    SystemFieldsMigrator.add_string_field!(
      "locale",
      to: FieldResourceType::USER,
      localized_name: LocalizedName.new(
        english: "Locale",
        indonesian: "Bahasa",
        japanese: "言語"
      ),
      nullable: false
    )

    SystemFieldsMigrator.add_string_field!(
      "role",
      to: FieldResourceType::USER,
      localized_name: LocalizedName.new(
        english: "Role",
        indonesian: "Peran",
        japanese: "役割"
      ),
      nullable: false
    )

    SystemFieldsMigrator.add_datetime_field!(
      "password_updated_at",
      to: FieldResourceType::USER,
      localized_name: LocalizedName.new(
        english: "Password Updated At",
        indonesian: "Kata Sandi Diperbarui Pada",
        japanese: "パスワード更新日時"
      ),
      nullable: false
    )

    # Add more system fields as needed for other resource types
  end
end

# Auto-load defaults when file is required
SystemFields.load_defaults
