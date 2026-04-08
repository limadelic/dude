module Dude
  module News
    class News
      MOCK_DATA_PATH = '/tmp/dude_news_mock_data.json'

      def initialize(limit: 5)
        @limit = limit
      end

      def run
        puts "Installed: #{installed_version}, Latest: #{latest_version}"
        puts "Smoke test: #{workflow_conclusion}"
        releases.take(@limit).each { |release| puts release }
      end

      private

      def installed_version
        @installed_version ||= ENV.fetch('CC_VERSION', 'unknown')
      end

      def latest_version
        @latest_version ||= fetch_if_mock('latest_version', 'unknown')
      end

      def workflow_conclusion
        @workflow_conclusion ||= fetch_if_mock('workflow_conclusion', 'unknown')
      end

      def releases
        @releases ||= fetch_if_mock('releases', [])
      end

      def fetch_if_mock(key, default)
        ENV['DUDE_NEWS_MOCK'] ? fetch_mock_data[key] : default
      end

      def fetch_mock_data
        @mock_data ||= parse_mock_file
      end

      def parse_mock_file
        require 'json'
        file_path = ENV['DUDE_NEWS_MOCK_DATA'] || MOCK_DATA_PATH
        return {} unless File.exist?(file_path)

        JSON.parse(File.read(file_path))
      end
    end
  end
end
