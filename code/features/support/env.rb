require 'open3'
require_relative 'activity_server'

module DudeHelper
  def dude(*args, stdin: nil)
    cmd = "bundle exec dude #{args.join(' ')}"
    output, _, status = Open3.capture3(cmd, stdin_data: stdin.to_s)
    raise "CLI failed: #{cmd}" unless status.success?
    output
  end
end

World(DudeHelper)

ActivityServer.start

at_exit do
  ActivityServer.stop
end
