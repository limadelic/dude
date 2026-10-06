module Dude
  module Transcript
    class SiloRegistry
      def initialize(path = default_path)
        @path = path
        @roster = {}
      end

      def load
        return unless File.exist?(@path)

        data = JSON.load_file(@path)
        @roster = data.dig('silos') || {}
      rescue JSON::ParserError, StandardError
        @roster = {}
      end

      def roster
        @roster
      end

      def silo_id(name)
        silo_data = @roster[name]
        silo_data&.dig('id')
      end

      private

      def default_path
        File.expand_path('~/dude/silos/silo/.claude/skills/silo/silos.json')
      end
    end
  end
end
