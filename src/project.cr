# Third party requirements.
require "marten"
require "mysql"
require "typed_env_config"

# Configuration requirements.
require "../config/settings/base"
require "../config/settings/**"
require "../config/routes"

# Project requirements.
require "./ligo/app"
