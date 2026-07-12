# Third party requirements.
require "envy"
require "http/web_socket"
require "marten"
require "marten_auth"
require "marten_smtp_emailing"
require "marten_s3"
require "csv"
require "sqlite3"
require "envy"
require "jbuilder"
require "mysql"
require "nanoid"
require "typed_env_config"
require "hashids"
require "email"
require "jwt"
require "rbacr"
require "sidekiq"
require "multi_auth"
require "aasm"
require "prorate"
require "halite"

# Require all middlewares
require "./middlewares/**"

# Project-specific patches (e.g. monkey-patching helpers)
require "./patches/**"

# Project-specific libraries
require "./lib/**"

# Configuration requirements.
require "../config/initializers/**"
require "../config/settings/base"
require "../config/settings/**"
require "../config/routes"

# Project requirements.
require "./handlers/concerns/**"
require "./handlers/request_handler"
require "./handlers/**"
require "./enums/**"
require "./models/concerns/**"
require "./models/**"
require "./serializers/model_serializer"
require "./serializers/**"
require "./services/**"
require "./schemas/concerns/**"
require "./schemas/base_schema"
require "./schemas/**"
require "./emails/**"
require "./jobs/**"
require "./errors"
require "./socky/app"
require "./auth/app"
require "./workaty/app"
require "./antrikan/app"
