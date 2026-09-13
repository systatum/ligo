require "./schemas/concerns/**"
require "./schemas/base_schema"
require "./lib/**"
require "./structs/**"
require "./errors"
require "./models/concerns/**"
require "./models/**"
require "./services/**"
require "./handlers/concerns/**"
require "./handlers/request_handler"
require "./handlers/**"
require "./middlewares/**"
require "./socky/**"
require "./serializers/**"
require "./schemas/**"

module Ligo
  class App < Marten::App
    label "ligo"
  end
end
