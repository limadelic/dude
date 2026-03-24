require 'thor'

module Dude
  class CLI < Thor
    desc "status_line", "Render status line"
    def status_line
      require_relative 'status_line'
      input = STDIN.read
      input = '{}' if input.strip.empty?
      StatusLine::Runner.new(input).run
    end
  end
end