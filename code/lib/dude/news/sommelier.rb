require_relative '../helpers/gh'

module Dude
  module News
    class Sommelier
      def initialize(gh: Dude::Helpers::Gh.new)
        @gh = gh
      end

      def taste(vintage)
        trigger(vintage)
        wait_for_completion
        conclude
      end

      private

      def workflow_conclusion
        opts = "--json conclusion -q '.[0].conclusion'"
        cmd = "run list --repo UKGEPIC/dude --branch main --limit 1 #{opts}"
        @gh.run(cmd)
      end

      def run_id
        @gh.run(run_id_cmd)
      end

      def trigger(vintage)
        cmd = "workflow run dude.yml -R UKGEPIC/dude -f prompt=\"1 + 1\" " \
              "-f version=#{vintage} -f timeout=5"
        @gh.run(cmd)
      end

      def wait_for_completion(max_retries: 60)
        max_retries.times { |attempt| return if poll(attempt, max_retries) }
        raise 'Run did not complete within timeout'
      end

      def conclude
        conclusion = workflow_conclusion
        url = run_url(conclusion)
        error = error_msg(conclusion)
        { conclusion: conclusion, url: url, error: error }
      end

      def error_logs(run_id)
        job_id = fetch_job_id(run_id)
        @gh.run("api repos/UKGEPIC/dude/actions/jobs/#{job_id}/logs")
      end

      def run_id_cmd
        opts = "--json databaseId -q '.[0].databaseId'"
        "run list --repo UKGEPIC/dude --branch main --limit 1 #{opts}"
      end

      def fetch_run_status
        cmd = "run list --repo UKGEPIC/dude --limit 1 " \
              "--json status -q '.[0].status'"
        @gh.run(cmd)
      end

      def poll(attempt, max_retries)
        return true if fetch_run_status == 'completed'

        sleep 5 unless attempt == max_retries - 1
        false
      end

      def fetch_job_id(run_id)
        cmd = "api repos/UKGEPIC/dude/actions/runs/#{run_id}/jobs " \
              "--jq '.jobs[0].id'"
        @gh.run(cmd)
      end

      def run_url(conclusion)
        id = run_id
        return nil if id.empty?

        "https://github.com/UKGEPIC/dude/actions/runs/#{id}"
      end

      def error_msg(conclusion)
        return nil unless conclusion == 'failure'

        error_logs(run_id)
      end
    end
  end
end
