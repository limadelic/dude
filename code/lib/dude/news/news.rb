require_relative '../helpers/json'

module Dude
  module News
    class News
      include Dude::Helpers::Json
      MOCK_DATA_PATH = '/tmp/dude_news_mock_data.json'

      def initialize(limit: 5)
        @limit = limit
      end

      def run
        puts "Installed: #{installed_version}, Latest: #{latest_version}"
        puts "Smoke test: #{workflow_conclusion}"
        puts run_url if workflow_conclusion == 'failure' && run_url
        releases.take(@limit).each { |release| puts release }
      end

      private

      def installed_version
        @installed_version ||= ENV.fetch('CC_VERSION', 'unknown')
      end

      def latest_version
        @latest_version ||= fetch_if_mock('latest_version') do
          cmd = "release list -R anthropics/claude-code --limit 1 "
          cmd += "--json tagName -q '.[0].tagName'"
          gh(cmd)
        end
      end

      def workflow_conclusion
        @workflow_conclusion ||= fetch_if_mock('workflow_conclusion') do
          cmd = "run list --repo UKGEPIC/dude --branch main "
          cmd += "--limit 1 --json conclusion -q '.[0].conclusion'"
          gh(cmd)
        end
      end

      def run_url
        @run_url ||= fetch_if_mock('run_url') do
          id = gh(run_id_cmd)
          id.empty? ? nil : "https://github.com/UKGEPIC/dude/actions/runs/#{id}"
        end
      end

      def run_id_cmd
        "run list --repo UKGEPIC/dude --branch main --limit 1 " \
          "--json databaseId -q '.[0].databaseId'"
      end

      def releases
        @releases ||= fetch_if_mock('releases') do
          output = gh(releases_cmd)
          output.split("\n").reject(&:empty?)
        end
      end

      def releases_cmd
        "release list -R anthropics/claude-code --limit #{@limit} " \
          "--json tagName -q '.[].tagName'"
      end

      def gh(cmd)
        `gh #{cmd}`.strip
      end

      def fetch_if_mock(key)
        if ENV['DUDE_NEWS_MOCK']
          fetch_mock_data[key]
        else
          yield
        end
      end

      def fetch_mock_data
        @mock_data ||= parse_mock_file
      end

      def parse_mock_file
        path = ENV['DUDE_NEWS_MOCK_DATA'] || MOCK_DATA_PATH
        read_json(path) || {}
      end
    end
  end
end
