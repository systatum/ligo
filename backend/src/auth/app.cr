require "./serializers/**"
require "./handlers/concerns/**"
require "./handlers/**"
require "./enums/**"
require "./models/concerns/**"
require "./models/**"
require "./routes"
require "./schemas/**"
require "./services/**"
require "./emails/**"

module Auth
  class App < Marten::App
    label "auth"
  end
end
