require "json"

module Ligo
  # Turns the app's named routes into a manifest clients can resolve,
  # for example `{ "schools:create": { path: "/api/schools/create", args: {} } }`.
  module RouteManifest
    record Entry, path : String, args : Hash(String, String) do
      include JSON::Serializable
    end

    def self.generate(
      routes : Marten::Routing::Map = Marten.routes,
      strip_prefix : String? = nil,
    ) : Hash(String, Entry)
      entries = {} of String => Entry
      collect(routes, "", nil, entries)

      prefix = strip_prefix.presence
      return entries unless prefix

      entries.transform_values do |entry|
        Entry.new(path: entry.path.lchop(prefix), args: entry.args)
      end
    end

    def self.json(
      routes : Marten::Routing::Map = Marten.routes,
      strip_prefix : String? = nil,
      pretty : Bool = true,
    ) : String
      manifest = generate(routes, strip_prefix)
      pretty ? manifest.to_pretty_json : manifest.to_json
    end

    private PARAMETER_RE = /<(?P<name>\w+)(?::(?P<type>[^>:]+))?>/

    private def self.collect(map, parent_path, parent_name, entries) : Nil
      map.rules.each do |rule|
        case rule
        when Marten::Routing::Rule::Path
          add_path(rule, parent_path, parent_name, entries)
        when Marten::Routing::Rule::Map
          collect(
            rule.map,
            parent_path + resolve_path(rule.path),
            qualify(parent_name, rule.name),
            entries
          )
        when Marten::Routing::Rule::Localized
          rule.rules.each do |localized_rule|
            case localized_rule
            when Marten::Routing::Rule::Path
              add_path(localized_rule, "/<locale>" + parent_path, nil, entries)
            when Marten::Routing::Rule::Map
              collect(
                localized_rule.map,
                "/<locale>" + parent_path + resolve_path(localized_rule.path),
                qualify(parent_name, localized_rule.name),
                entries
              )
            end
          end
        end
      end
    end

    private def self.add_path(rule, parent_path, parent_name, entries) : Nil
      raw_path = parent_path + resolve_path(rule.path)
      entries[qualify(parent_name, rule.name)] = Entry.new(
        path: placeholder_path(raw_path),
        args: arguments(raw_path)
      )
    end

    private def self.qualify(parent : String?, name : String) : String
      parent ? "#{parent}:#{name}" : name
    end

    private def self.resolve_path(path) : String
      case path
      when Marten::Routing::TranslatedPath
        I18n.t(path.key)
      else
        path.to_s
      end
    end

    private def self.placeholder_path(path : String) : String
      path.gsub(PARAMETER_RE) do |match|
        name = match.lchop('<').split(/[:>]/).first
        ":#{name}"
      end
    end

    private def self.arguments(path : String) : Hash(String, String)
      args = {} of String => String
      path.scan(PARAMETER_RE) do |match|
        args[match["name"]] = match["type"]? == "int" ? "integer" : "string"
      end
      args
    end
  end
end
