require_relative 'paperboy'
require_relative 'sommelier'

module Dude
  module News
    class News
      def initialize(limit: 5, paperboy: Paperboy.new, sommelier: Sommelier.new)
        @limit = limit
        @paperboy = paperboy
        @sommelier = sommelier
      end

      def fetch
        latest = @paperboy.latest_version
        lines = [installed_and_latest_line(latest)]
        lines.concat(releases_lines)
        lines.concat(smoke_test_lines(latest))
        lines.join("\n")
      end

      private

      def installed_version
        @installed_version ||= ENV.fetch('CC_VERSION', 'unknown')
      end

      def installed_and_latest_line(latest)
        installed = installed_version
        "Installed: #{installed}, Latest: #{latest}"
      end

      def releases_lines
        @paperboy.releases(@limit)
      end

      def smoke_test_lines(latest)
        result = @sommelier.taste(latest)
        [
          smoke_test_conclusion(latest, result), smoke_test_url(result),
          smoke_test_error(result)
        ].compact
      end

      def smoke_test_conclusion(latest, result)
        version = latest.start_with?('v') ? latest[1..-1] : latest
        "Vintage #{version}: #{result[:conclusion]}"
      end

      def smoke_test_url(result)
        result[:url]
      end

      def smoke_test_error(result)
        result[:error]
      end
    end
  end
end
