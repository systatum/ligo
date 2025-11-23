module ExceptionsHandler
  macro included
    rescue_from Marten::HTTP::Errors::PermissionDenied do
      handle_permission_denied(error)
    end

    rescue_from Marten::HTTP::Errors::NotFound,
      Marten::DB::Errors::RecordNotFound do
      handle_not_found(error)
    end

    rescue_from Exception do
      handle_generic_error(error)
    end
  end

  private def handle_permission_denied(e)
    debug_exception(e)
    render_error 403, ["Not authorized"]
  end

  private def handle_not_found(e)
    debug_exception(e)
    render_error 404, ["Not found"]
  end

  private def handle_generic_error(e)
    debug_exception(e)
    render_error 400, [e.message || "Unknown error"]
  end

  private def debug_exception(e)
    if ENV["MARTEN_ENV"] == "test"
      puts e.message
      e.backtrace.each do |line|
        # skip noise lines
        next if line.includes?("lib/marten") || line.includes?("marten/src/") ||
                line.includes?("crystal/src") || line.includes?("crystal/core/") ||
                line.includes?("??")

        puts "#{line}\n"
      end

      puts "\n"
    end
  end
end
