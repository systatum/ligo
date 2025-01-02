# Third party requirements.
require "marten"
require "sqlite3"

# Configuration requirements.
require "../config/settings/base"
require "../config/settings/**"
require "../config/initializers/**"
require "../config/routes"

# Project requirements.
require "./handlers/**"
require "./models/**"
require "./schemas/**"
