require 'json'

module Dude
  module Transcript
    class TranscriptUsage
      def parse(line)
        parsed = parse_line(line)
        return nil unless parsed

        usage = parsed.dig('message', 'usage')
        return nil unless usage

        {
          id: parsed.dig('message', 'id'),
          model: parsed.dig('message', 'model'),
          usage: usage,
          epoch: Time.iso8601(parsed['timestamp']).to_i,
          session: parsed['sessionId']
        }
      end

      private

      def parse_line(line)
        JSON.parse(line.strip)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
