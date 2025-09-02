require "net/http"
require "time"
require "fileutils"

logdir = File.expand_path("/home/systatum/server-logs")
FileUtils.mkdir_p(logdir)

begin
  res = Net::HTTP.get_response(URI("http://127.0.0.1:3000/ping"))
  if res.is_a?(Net::HTTPSuccess)
    fname = File.join(logdir, "prod_server_fine_#{Time.now.strftime("%Y_%m_%d_%H")}.txt")
    File.open(fname, "a") { |f| f.puts "." }
  else
    raise "bad status"
  end
rescue
  system("sudo systemctl restart ligo-prod.service")

  crashlog = File.join(logdir, "prod_server_crashes.txt")
  File.open(crashlog, "a") { |f| f.puts Time.now.strftime("%A %b %d %Y at %H:%M") }
end
