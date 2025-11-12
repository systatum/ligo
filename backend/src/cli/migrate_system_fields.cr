require "../lib/system_fields_migrator"
require "../config/system_fields"

class MigrateSystemFields < Marten::CLI::Command
  help "Migrate system fields definitions to the database"

  @verbose : Bool = false
  @dry_run : Bool = false
  @clear : Bool = false

  def setup
    on_option(
      :v,
      :verbose,
      "Show detailed migration output"
    ) { @verbose = true }

    on_option(
      :d,
      :dry_run,
      "Show what would be migrated without making changes"
    ) { @dry_run = true }

    on_option(
      :c,
      :clear,
      "Clear all registered fields before running (useful for testing)"
    ) { @clear = true }
  end

  def run
    print_header

    if @clear
      print_verbose "Clearing all registered fields..."
      SystemFieldsMigrator.clear!
      print_success "✓ Cleared registered fields"
      print_verbose ""

      begin
        SystemFields.load_defaults
        print_success "✓ Reloaded default system fields"
      rescue ex
        print_error "✗ Failed to reload default system fields: #{ex.message}"
        exit(1)
      end
    end

    if @dry_run
      run_dry_run
    else
      run_migration
    end
  end

  private def run_migration
    print_verbose "Starting system fields migration..."
    print_verbose ""

    begin
      SystemFieldsMigrator.verbose = @verbose
      result = SystemFieldsMigrator.migrate!
      print ""
      print_success "✓ System fields migration completed successfully!"
      print_summary(result)
    rescue ex
      print_error "✗ Migration failed: #{ex.message}"
      exit(1)
    end
  end

  private def run_dry_run
    print_warning "DRY RUN MODE - No changes will be made"
    print_verbose ""

    fields = SystemFieldsMigrator.fields

    if fields.empty?
      print_warning "No system fields are registered."
      print_verbose "Make sure src/config/system_fields.cr is loaded and defines fields."
      return
    end

    create_count = 0
    update_count = 0
    skip_count = 0

    fields.group_by(&.resource_type).each do |resource_type, resource_fields|
      print_verbose "#{resource_type}:"

      resource_fields.each do |config|
        existing_field = FieldDefinition.find_by_name_and_resource_type(
          config.name,
          config.resource_type
        )

        if existing_field
          changes = detect_changes(existing_field, config)

          if changes.empty?
            print_skip "  → #{config.name} (no changes needed)"
            skip_count += 1
          else
            print_update "  ✎ #{config.name} (would update)"
            changes.each { |change| print_verbose "      • #{change}" }
            update_count += 1
          end
        else
          print_create "  + #{config.name} (would create)"
          print_field_details(config)
          create_count += 1
        end
      end

      print_verbose ""
    end

    print_dry_run_summary(create_count, update_count, skip_count)
  end

  private def detect_changes(existing : FieldDefinition, config : SystemFieldsMigrator::FieldDefinitionConfig) : Array(String)
    changes = [] of String

    if existing.data_type != config.data_type
      changes << "data_type: #{existing.data_type} → #{config.data_type}"
    end

    if existing.nullable != config.nullable
      changes << "nullable: #{existing.nullable} → #{config.nullable}"
    end

    if existing.uniqueness != config.uniqueness
      changes << "uniqueness: #{existing.uniqueness} → #{config.uniqueness}"
    end

    if config.localized_name
      if !existing.localized_name_equal_to?(config.localized_name)
        changes << "localized_name: updated"
      end
    end

    if !existing.is_system_field
      changes << "is_system_field: false → true"
    end

    changes
  end

  private def print_field_details(config : SystemFieldsMigrator::FieldDefinitionConfig)
    print_verbose "      • type: #{config.data_type}"
    print_verbose "      • nullable: #{config.nullable}"
    print_verbose "      • uniqueness: #{config.uniqueness}"
    if config.localized_name
      print_verbose "      • localized_name: #{config.localized_name.to_json}"
    end
  end

  private def print_summary(result)
    print ""
    print_summary_header "Summary:"
    print_success "  Created: #{result[:created]}"
    print_update "  Updated: #{result[:updated]}"
    print_skip "  Skipped: #{result[:skipped]}"
    print_total "  Total:   #{result[:total]}"
  end

  private def print_dry_run_summary(create : Int32, update : Int32, skip : Int32)
    total = create + update + skip

    print_separator
    print_summary_header "Dry Run Summary:"
    print_create "  Would create: #{create}"
    print_update "  Would update: #{update}"
    print_skip "  Would skip:   #{skip}"
    print_total "  Total:        #{total}"
    print_separator
    print ""
    print_warning "Run without --dry-run to apply these changes"
  end

  private def print_header
    return unless @verbose || @dry_run
    print_verbose "=" * 60
    print_verbose "System Fields Migration"
    print_verbose "=" * 60
    print_verbose ""
  end

  private def print(message : String)
    stdout.puts message
  end

  private def print_verbose(message : String)
    stdout.puts message if @verbose || @dry_run
  end

  private def print_success(message : String)
    stdout.puts "\e[32m#{message}\e[0m"
  end

  private def print_error(message : String)
    stderr.puts "\e[31m#{message}\e[0m"
  end

  private def print_warning(message : String)
    stdout.puts "\e[33m#{message}\e[0m"
  end

  private def print_create(message : String)
    stdout.puts "\e[32m#{message}\e[0m"
  end

  private def print_update(message : String)
    stdout.puts "\e[34m#{message}\e[0m"
  end

  private def print_skip(message : String)
    stdout.puts "\e[90m#{message}\e[0m"
  end

  private def print_summary_header(message : String)
    stdout.puts "\e[1m\e[36m#{message}\e[0m"
  end

  private def print_total(message : String)
    stdout.puts "\e[1m#{message}\e[0m"
  end

  private def print_separator
    stdout.puts "\e[36m#{"─" * 60}\e[0m"
  end
end
