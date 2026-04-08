require_relative 'github_source'

module Dude
  module News
    class News
      def initialize(limit: 5, source: GithubSource.new)
        @limit = limit
        @source = source
      end

      def run
        puts "Installed: #{installed_version}, Latest: #{@source.latest_version}"
        conclusion = @source.workflow_conclusion
        puts "Smoke test: #{conclusion}"
        url = @source.run_url
        puts url if conclusion == 'failure' && url
        @source.releases(@limit).each { |release| puts release }
      end

      private

      def installed_version
        @installed_version ||= ENV.fetch('CC_VERSION', 'unknown')
      end
    end
  end
end
