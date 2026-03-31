require 'open3'
require_relative 'activity_server'
require_relative 'dude_test_process'
require_relative '../dude/helpers/cli'

module Cuke
  module DudeHelper
    def dude(*args, stdin: nil, chdir: nil)
      cmd = "dude #{args.join(' ')}"
      opts = build_command_options(stdin, chdir)
      execute_dude_command(cmd, opts)
    end

    def build_command_options(stdin, chdir)
      opts = { stdin_data: stdin.to_s }
      opts[:chdir] = chdir if chdir
      opts
    end

    def execute_dude_command(cmd, opts)
      output, _, status = Open3.capture3(cmd, **opts)
      raise "CLI failed: #{cmd}" unless status.success?
      output
    end
  end

  class Env
  end
end

World(Cuke::DudeHelper)

Cuke::ActivityServer.start

at_exit do
  Cuke::ActivityServer.stop
end
