require 'json'

module Dude
  module Transcript
    module LineParser
      def parse_line(line)
        JSON.parse(line.strip)
      rescue JSON::ParserError
        nil
      end
    end
  end
end
