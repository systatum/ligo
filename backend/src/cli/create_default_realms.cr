require "../lib/default_realms_seeder"

# On-demand only - never wired into `migrate`, CI, or bin/run_specs. Run
# manually with `mybin/manage create_default_realms` when you want a fresh
# local checkout to have working Antrikan/Workaty realms.
class CreateDefaultRealms < Marten::CLI::Command
  help "Create default dev-only Realms for Antrikan and Workaty (idempotent, local/dev use only)"

  @verbose : Bool = false
  @dryrun : Bool = false

  def setup
    on_option(
      :v,
      :verbose,
      "Show detailed output"
    ) { @verbose = true }

    on_option(
      :d,
      :dryrun,
      "Show what would be created without making changes"
    ) { @dryrun = true }
  end

  def run
    if Marten.env.production?
      print_error "✗ Refusing to run in production - this command seeds fixed, publicly-known dev credentials."
      exit(1)
    end

    if @dryrun
      run_dry_run
    else
      run_seed
    end
  end

  private def run_seed
    print_verbose "Seeding default realms..."

    begin
      result = DefaultRealmsSeeder.seed!
      print_success "✓ Default realms are ready"
      print_summary(result)
    rescue ex
      print_error "✗ Failed: #{ex.message}"
      exit(1)
    end
  end

  private def run_dry_run
    print_warning "DRY RUN MODE - No changes will be made"

    create_count = 0
    skip_count = 0

    DefaultRealmsSeeder::SEEDS.each do |seed|
      if Auth::Realm.filter(id: seed.id).exists?
        print_skip "  → #{seed.id} (already exists)"
        skip_count += 1
      else
        print_create "  + #{seed.id} (would create)"
        create_count += 1
      end
    end

    print ""
    print_summary_header "Dry Run Summary:"
    print_create "  Would create: #{create_count}"
    print_skip "  Would skip:   #{skip_count}"
    print ""
    print_warning "Run without --dryrun to apply these changes"
  end

  private def print_summary(result)
    print ""
    print_summary_header "Summary:"
    print_success "  Created: #{result[:created]}"
    print_skip "  Skipped: #{result[:skipped]}"
    print_total "  Total:   #{result[:total]}"
  end

  private def print(message : String)
    stdout.puts message
  end

  private def print_verbose(message : String)
    stdout.puts message if @verbose || @dryrun
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

  private def print_skip(message : String)
    stdout.puts "\e[90m#{message}\e[0m"
  end

  private def print_summary_header(message : String)
    stdout.puts "\e[1m\e[36m#{message}\e[0m"
  end

  private def print_total(message : String)
    stdout.puts "\e[1m#{message}\e[0m"
  end
end
