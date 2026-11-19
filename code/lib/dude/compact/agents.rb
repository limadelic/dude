require 'json'
require 'open3'
require_relative 'agents/error'

module Dude
  class Compact
    class Agents
      COMMAND = %w[claude agents --json]
      MISSING = 'compact error: claude not found'
      FAILED = 'compact error: claude agents failed'
      BAD_JSON = 'compact error: claude agents gave bad JSON'

      def initialize(name)
        @name = name
      end

      def find
        sessions = rows
        matches = sessions.select { |row| row['name'] == @name }
        raise Error, unknown_message(sessions) if matches.empty?
        raise Error, ambiguous_message(matches) if matches.size > 1

        matches.first
      end

      private

      def rows
        Array(JSON.parse(output)).grep(Hash)
      rescue JSON::ParserError
        raise Error, BAD_JSON
      end

      def output
        out, status = Open3.capture2(*COMMAND)
        raise Error, FAILED unless status.success?

        out
      rescue Errno::ENOENT
        raise Error, MISSING
      end

      def unknown_message(sessions)
        candidates = names(sessions).join(', ')
        "compact error: no silo named #{@name}, candidates: #{candidates}"
      end

      def names(sessions)
        sessions.map { |row| row['name'] }.compact
      end

      def ambiguous_message(matches)
        "compact error: two silos named #{@name}: #{places(matches)}"
      end

      def places(matches)
        matches.map { |row| "#{row['sessionId']} (#{row['cwd']})" }.join(', ')
      end
    end
  end
end
