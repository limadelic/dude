require_relative '../dude/news/news'

module Cuke
  module News
    def setup_installed_version(version)
      @installed_version = version
      ENV['CC_VERSION'] = version
    end

    def setup_latest_version(version)
      @latest_version = version
    end

    def setup_workflow_conclusion(conclusion)
      @workflow_conclusion = conclusion
    end

    def news_output
      @output ||= ''
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

    def extract_limit_from_args(args)
      match = args.match(/--limit\s+(\d+)/)
      match ? match[1].to_i : nil
    end

    def verify_releases(releases)
      output = news_output
      releases.each do |release|
        msg = "Expected release #{release} in output:\n#{output}"
        raise msg unless output.include?(release)
      end
    end

    def capture_output
      out = $stdout = StringIO.new
      yield
      out.string
    ensure
      $stdout = STDOUT
    end
  end
end
