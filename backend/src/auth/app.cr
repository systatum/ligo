require "./emails/**"
require "./handlers/**"
require "./enums/**"
require "./models/**"
require "./routes"
require "./schemas/**"

module Auth
  class App < Marten::App
    label "auth"
  end
end
