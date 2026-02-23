require "./handlers/concerns/**"
require "./handlers/**"
require "./models/concerns/**"
require "./models/**"
require "./routes"
require "./schemas/**"
require "./serializers/**"

module Antrikan
  class App < Marten::App
    label "antrikan"
  end
end
