require_relative '../helpers/wait'

module Dude
  module Dudes
    class AlleyPr
      def execute
        branch = get_branch
        guard_main_branch(branch)
        run_url = trigger_and_wait_for_workflow(branch)
        complete_workflow(branch, run_url)
      end

      private

      def trigger_and_wait_for_workflow(branch)
        push_and_trigger(branch)
        run_id = wait_for_workflow_completion
        run_url = build_run_url(run_id)
        check_workflow_success(run_url)
        run_url
      end

      def push_and_trigger(branch)
        `git push -u origin #{branch} 2>&1`
        `gh workflow run dude.yml --ref #{branch}`
      end

      def wait_for_workflow_completion
        run_id = get_run_id
        Helpers::Wait.new.until { completed?(run_id) }
        run_id
      end

      def get_run_id
        `gh run list --json databaseId -q '.[0].databaseId'`.strip
      end

      def completed?(run_id)
        status = `gh run list --json status -q '.[0].status'`.strip
        status == 'completed'
      end

      def build_run_url(run_id)
        repo = extract_repo_from_remote
        "https://github.com/#{repo}/actions/runs/#{run_id}"
      end

      def extract_repo_from_remote
        remote = `git remote get-url origin`.strip
        remote.match(%r{github\.com[:/](.+?)(?:\.git)?$})[1]
      end

      def check_workflow_success(run_url)
        run_id = run_url.split('/')[-1]
        conclusion = `gh run list --json conclusion -q '.[0].conclusion'`.strip
        raise "Workflow failed: #{run_url}" unless conclusion == 'success'
      end

      def complete_workflow(branch, run_url)
        pr_url = find_pr(branch, run_url)
        warn_multiple_prs(pr_url) if multiple_prs?(branch, run_url)
        `echo "#{pr_url}" | pbcopy`
        `git commit --allow-empty -m "[skip ci]" && git push`
        pr_url
      end

      def find_pr(branch, run_url)
        pr_urls = fetch_prs(branch, run_url)
        pr_urls.last
      end

      def multiple_prs?(branch, run_url)
        fetch_prs(branch, run_url).length > 1
      end

      def fetch_prs(branch, run_url)
        cmd = "gh pr list --head #{branch} --state open --json url -q '.[].url'"
        prs = `#{cmd}`.strip
        raise "No PR found: #{run_url}" if prs.empty?

        prs.split("\n")
      end

      def warn_multiple_prs(pr_url)
        puts 'Multiple PRs found, using newest'
      end

      def get_branch
        `git branch --show-current`.strip
      end

      def guard_main_branch(branch)
        raise 'Cannot run on main branch' if branch == 'main'
      end
    end
  end
end
