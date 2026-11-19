require 'json'
require 'open3'

module Dude
  class Compact
    class Agents
      class Error < StandardError; end

      COMMAND = %w[claude agents --json]
      MISSING = 'compact error: claude not found'
      FAILED = 'compact error: claude agents failed'
      BAD_JSON = 'compact error: claude agents gave bad JSON'

      def initialize(name)
        @name = name
      end

      def find
        matches = named
        raise Error, unknown_message if matches.empty?
        raise Error, ambiguous_message(matches) if matches.size > 1

        matches.first
      end

      private

      def named
        rows.select { |row| row['name'] == @name }
      end

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

      def unknown_message
        "compact error: no silo named #{@name}, candidates: #{names.join(', ')}"
      end

      def names
        rows.map { |row| row['name'] }.compact
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
