require "./serializers/**"
require "./enums/**"
require "./models/concerns/**"
require "./models/**"
require "./schemas/**"
require "./services/**"
require "./handlers/concerns/**"
require "./handlers/**"
require "./routes"
require "./jobs/**"
require "./emails/**"

module Auth
  class App < Marten::App
    label "auth"
  end
end
