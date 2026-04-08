ENV.delete('TERMINAL_EMULATOR')

require 'simplecov'
SimpleCov.command_name 'cucumber'

require 'open3'
require_relative 'activity_server'
require_relative 'dude'
require_relative 'status_line_result'
require_relative 'status_line'
require_relative '../dude/helpers/cli'

module Cuke
  class Env
  end
end

Cuke::ActivityServer.start

at_exit do
  Cuke::ActivityServer.stop
end
