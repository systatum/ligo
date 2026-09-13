# Third party requirements.
require "base64"
require "big"
require "digest"
require "jwt"
require "marten"
require "marten_auth"
require "mime"
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
