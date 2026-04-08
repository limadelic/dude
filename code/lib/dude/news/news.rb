require_relative 'github_source'

module Dude
  module News
    class News
      def initialize(limit: 5, source: GithubSource.new)
        @limit = limit
        @source = source
      end

      def run
        print_installed_and_latest
        print_smoke_test_status
        @source.releases(@limit).each { |release| puts release }
      end

      private

      def installed_version
        @installed_version ||= ENV.fetch('CC_VERSION', 'unknown')
      end

      def print_installed_and_latest
        installed = installed_version
        latest = @source.latest_version
        puts "Installed: #{installed}, Latest: #{latest}"
      end

      def print_smoke_test_status
        conclusion = @source.workflow_conclusion
        puts "Smoke test: #{conclusion}"
        url = @source.run_url
        puts url if conclusion == 'failure' && url
      end
    end
  end
end
