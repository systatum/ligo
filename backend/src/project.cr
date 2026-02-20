# Third party requirements.
require "envy"
require "marten"
require "marten_auth"
require "marten_smtp_emailing"
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

# Require all middlewares
require "./middlewares/**"

# Project-specific extensions (e.g. request helpers)
require "./extensions/**"

# Project-specific libraries
require "./lib/**"

# Configuration requirements.
require "../config/settings/base"
require "../config/settings/**"
require "../config/initializers/**"
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
require "./schemas/base_schema"
require "./schemas/**"
require "./emails/**"
require "./auth/app"
require "./workaty/app"
