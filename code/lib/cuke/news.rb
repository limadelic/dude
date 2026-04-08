require_relative 'activity_server'

module Cuke
  module News
    def setup_installed_version(version)
      @installed_version = version
      ENV['CC_VERSION'] = version
      update_mock_endpoints
    end

    def setup_latest_version(version)
      @latest_version = version
      update_mock_endpoints
    end

    def setup_workflow_conclusion(conclusion)
      @workflow_conclusion = conclusion
      update_mock_endpoints
    end

    def run_dude_news(args = '')
      ENV['DUDE_NEWS_MOCK'] = 'true'
      cmd = "dude news #{args}".strip
      @news_output = dude(*cmd.split(' '))
    end

    def news_output
      @news_output ||= ''
    end

    def mock_releases_for(limit)
      all_releases = %w[
        v2.1.96 v2.1.95 v2.1.94 v2.1.93 v2.1.92 v2.1.91 v2.1.90
        v2.1.89 v2.1.88 v2.1.87
      ]
      all_releases.take(limit)
    end

    def assert_output_contains(text)
      output = news_output
      msg = "Expected '#{text}' in output:\n#{output}"
      raise msg unless output.include?(text)
    end

    def assert_output_starts_with(text)
      output = news_output
      first_line = output.split("\n").first
      msg = "Expected '#{text}' at top (got: '#{first_line}'):\n#{output}"
      raise msg unless first_line&.include?(text)
    end

    def assert_releases_in_output(count)
      verify_releases(mock_releases_for(count))
    end

    def assert_link_to_run_logs
      output = news_output
      has_github = output.include?('github.com')
      has_actions = output.include?('actions/runs')
      msg = "Expected GitHub Actions run link in output:\n#{output}"
      raise msg unless has_github && has_actions
    end

    def assert_headline_contains(text)
      assert_output_starts_with(text)
    end

    def assert_status_contains(text)
      assert_output_contains(text)
    end

    def assert_status_has_logs
      assert_link_to_run_logs
    end

    def assert_releases_count(count)
      assert_releases_in_output(count)
    end

    private

    def verify_releases(releases)
      output = news_output
      releases.each do |release|
        msg = "Expected release #{release} in output:\n#{output}"
        raise msg unless output.include?(release)
      end
    end

    def update_mock_endpoints
      # High-level mock data — no API internals
      response = {
        installed_version: @installed_version,
        latest_version: @latest_version,
        releases: mock_releases_for(10),
        workflow_conclusion: @workflow_conclusion,
        workflow_run_id: 12345
      }
      Cuke::ActivityServer.set_response(response)
    end
  end
end
