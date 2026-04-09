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
        print_installed_and_latest
        print_smoke_test_status
        @paperboy.releases(@limit).each { |release| puts release }
      end

      private

      def installed_version
        @installed_version ||= ENV.fetch('CC_VERSION', 'unknown')
      end

      def print_installed_and_latest
        installed = installed_version
        latest = @paperboy.latest_version
        puts "Installed: #{installed}, Latest: #{latest}"
      end

      def print_smoke_test_status
        conclusion = @sommelier.workflow_conclusion
        puts "Smoke test: #{conclusion}"
        url = @sommelier.run_url
        puts url if conclusion == 'failure' && url
      end
    end
  end
end
