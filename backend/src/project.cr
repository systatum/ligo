# Third party requirements.
require "marten"
require "marten_auth"
require "sqlite3"
require "envy"
require "jbuilder"
require "mysql"
require "nanoid"
require "hashids"
require "jwt"

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
require "./schemas/**"
require "./auth/app"
