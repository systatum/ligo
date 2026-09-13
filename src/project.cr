# Third party requirements.
require "big"
require "jwt"
require "marten"
require "marten_auth"
require "mysql"
require "nanoid"
require "hashids"
require "typed_env_config"

# Configuration requirements.
require "../config/initializers/**"
require "../config/settings/base"
require "../config/settings/**"
require "../config/routes"

# Project requirements.
require "./ligo/app"
