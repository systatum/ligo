# Third party requirements.
require "marten"
require "marten_auth"
require "sqlite3"
require "envy"
require "jbuilder"
require "mysql"
require "nanoid"

# Configuration requirements.
require "../config/settings/base"
require "../config/settings/**"
require "../config/initializers/**"
require "../config/routes"

# Project requirements.
require "./handlers/**"
require "./enums/**"
require "./models/concerns/**"
require "./models/**"
require "./schemas/**"
require "./auth/app"
