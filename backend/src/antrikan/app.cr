require "./errors.cr"
require "./handlers/concerns/**"
require "./handlers/**"
require "./models/concerns/**"
require "./models/**"
require "./routes"
require "./schemas/**"
require "./serializers/**"
require "./services/space/concerns/**"
require "./services/**"

module Antrikan
  class App < Marten::App
    label "antrikan"
  end
end
