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

      def run
        latest = @paperboy.latest_version
        print_installed_and_latest(latest)
        @paperboy.releases(@limit).each { |release| puts release }
        result = @sommelier.taste(latest)
        print_smoke_test_result(result, latest)
      end

      private

      def installed_version
        @installed_version ||= ENV.fetch('CC_VERSION', 'unknown')
      end

      def print_installed_and_latest(latest)
        installed = installed_version
        puts "Installed: #{installed}, Latest: #{latest}"
      end

      def print_smoke_test_result(result, latest)
        version = latest.start_with?('v') ? latest[1..-1] : latest
        puts "Vintage #{version}: #{result[:conclusion]}"
        puts result[:url] if result[:url]
        puts result[:error] if result[:error]
      end
    end
  end
end
