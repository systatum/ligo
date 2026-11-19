require "../route_manifest"

module Ligo
  # `manage routes:export` writes the route manifest as JSON.
  class RoutesExportCommand < Marten::CLI::Command
    command_name "routes:export"
    help "Export the app's named routes as a JSON manifest"

    @output : String? = nil
    @strip_prefix : String? = nil

    def setup
      on_option_with_arg("o", "output", "path", "Write the manifest to this file") do |value|
        @output = value
      end
      on_option_with_arg("p", "strip-prefix", "prefix", "Remove a path prefix from exported paths") do |value|
        @strip_prefix = value
      end
    end

    def run
      manifest = Ligo::RouteManifest.generate(strip_prefix: @strip_prefix)
      json = manifest.to_pretty_json

      if (path = @output)
        File.write(path, "#{json}\n")
        stdout.puts("Exported #{manifest.size} routes to #{path}")
      else
        stdout.puts(json)
      end
    end
  end
end
