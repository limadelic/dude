require 'json'

module Dude
  module Transcript
    class RequestCounter
      def count(path)
        return {} unless File.exist?(path)

        counts = {}
        seen_ids = Set.new

        File.read(path).each_line do |line|
          parsed = parse_line(line)
          next unless parsed

          model = parsed['message']&.dig('model')
          id = parsed['message']&.dig('id')

          next unless model && id
          next if seen_ids.include?(id)

          family = extract_family(model)
          next unless family

          seen_ids.add(id)
          counts[family] = (counts[family] || 0) + 1
        end

        counts
      rescue IOError
        {}
      end

      private

      def parse_line(line)
        JSON.parse(line.strip)
      rescue JSON::ParserError
        nil
      end

      def extract_family(model)
        %w[opus haiku sonnet fable].find { |family| model.include?(family) }
      end
    end
  end
end
