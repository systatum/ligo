require "./emails/**"
require "./serializers/**"
require "./handlers/concerns/**"
require "./handlers/**"
require "./models/concerns/**"
require "./models/**"
require "./routes"
require "./schemas/**"

module Workaty
  class App < Marten::App
    label "workaty"
  end
end
