require_relative '../helpers/wait'

module Dude
  module Dudes
    class AlleyPr
      def execute
        branch = `git branch --show-current`.strip
        guard_main_branch(branch)
        workflow_pr(branch)
      end

      private

      def workflow_pr(branch)
        run_url = trigger_and_wait_for_workflow(branch)
        complete_workflow(branch, run_url)
      end

      def trigger_and_wait_for_workflow(branch)
        push_and_trigger(branch)
        run_id = wait_for_workflow_completion
        build_run_url(run_id).tap { |url| check_workflow_success(run_id) }
      end

      def push_and_trigger(branch)
        `git push -u origin #{branch} 2>&1`
        prompt = 'Create a pull request for this branch'
        `gh workflow run dude.yml --ref #{branch} -f prompt="#{prompt}"`
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

      def ukgepic?
        extract_org_from_remote == 'UKGEPIC'
      end

      def extract_org_from_remote
        extract_repo_from_remote.split('/')[0]
      end

      def extract_repo_from_remote
        remote = `git remote get-url origin`.strip
        remote.match(%r{github\.com[:/](.+?)(?:\.git)?$})[1]
      end

      def check_workflow_success(run_id)
        cmd = "gh run view #{run_id} --json conclusion -q '.conclusion'"
        conclusion = `#{cmd}`.strip
        return if conclusion == 'success'

        raise "Workflow failed: #{build_run_url(run_id)}"
      end

      def complete_workflow(branch, run_url)
        prs = fetch_prs(branch, run_url)
        pr_url = prs.last
        finalize_workflow(pr_url, prs, run_url)
      end

      def finalize_workflow(pr_url, prs, run_url)
        puts 'Multiple PRs found, using newest' if prs.length > 1
        copy_pr_to_clipboard(pr_url)
        push_skip_ci_commit
        pr_url
      end

      def fetch_prs(branch, run_url)
        prs = query_pr_list(branch)
        raise "No PR found: #{run_url}" if prs.empty?

        prs.split("\n")
      end

      def query_pr_list(branch)
        cmd = "gh pr list --head #{branch} --state open --json url -q '.[].url'"
        `#{cmd}`.strip
      end

      def copy_pr_to_clipboard(pr_url)
        `echo "#{pr_url}" | pbcopy`
      end

      def push_skip_ci_commit
        `git commit --allow-empty -m "[skip ci]" && git push`
      end

      def guard_main_branch(branch)
        raise 'Cannot run on main branch' if branch == 'main'
      end
    end
  end
end
