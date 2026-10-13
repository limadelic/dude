require 'json'
require 'time'
require_relative 'line_parser'

module Dude
  module Transcript
    class TranscriptUsage
      include LineParser

      def parse(line)
        parsed = parse_line(line)
        return nil unless parsed && has_usage?(parsed)

        timestamp = parse_timestamp(parsed['timestamp'])
        return nil unless timestamp

        build_result(parsed, timestamp)
      end

      private

      def has_usage?(parsed)
        !!parsed.dig('message', 'usage')
      end

      def build_result(parsed, timestamp)
        {
          id: parsed.dig('message', 'id'),
          model: parsed.dig('message', 'model'),
          usage: parsed.dig('message', 'usage'),
          epoch: timestamp.to_i,
          session: parsed['sessionId']
        }
      end

      def parse_timestamp(timestamp_str)
        Time.iso8601(timestamp_str)
      rescue ArgumentError, TypeError
        nil
      end
    end
  end
end
