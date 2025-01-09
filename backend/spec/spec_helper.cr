ENV["MARTEN_ENV"] = "test"

require "spec"

require "../src/project"
require "marten/spec"
require "./factories/**"

def date_time_format
  /\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/
end
