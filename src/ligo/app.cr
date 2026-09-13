require "./models/concerns/**"
require "./models/**"
require "./handlers/concerns/**"
require "./handlers/**"
require "./serializers/**"
require "./services/**"
require "./schemas/**"

module Ligo
  class App < Marten::App
    label "ligo"
  end
end
