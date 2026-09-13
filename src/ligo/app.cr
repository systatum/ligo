require "./lib/**"
require "./errors"
require "./models/concerns/**"
require "./models/**"
require "./services/**"
require "./handlers/concerns/**"
require "./handlers/**"
require "./middlewares/**"
require "./serializers/**"
require "./schemas/**"

module Ligo
  class App < Marten::App
    label "ligo"
  end
end
