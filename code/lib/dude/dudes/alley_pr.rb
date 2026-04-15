module Dude
  module Dudes
    class AlleyPr
      def initialize
        @gh = Helpers::Gh.create
      end

      def execute
        branch = get_branch
        guard_main_branch(branch)
        run_push_and_workflow(branch)
      end

      def run_push_and_workflow(branch)
        run_command("git push -u origin #{branch} 2>&1")
        trigger_workflow(branch)
        run_id = wait_for_workflow_completion
        run_url = build_run_url(run_id)
        check_and_publish(branch, run_url)
      end

      def check_and_publish(branch, run_url)
        check_workflow_success(run_url)
        pr_url = find_and_select_pr(branch, run_url)
        publish_to_clipboard_and_skip_ci(pr_url)
        pr_url
      end

      def wait_for_workflow_completion
        run_id = get_run_id
        wait_for_completion(run_id)
        run_id
      end

      def build_run_url(run_id)
        repo = extract_repo_from_remote
        "https://github.com/#{repo}/actions/runs/#{run_id}"
      end

      def publish_to_clipboard_and_skip_ci(pr_url)
        run_command("echo #{pr_url} | pbcopy")
        run_command('git commit --allow-empty -m "[skip ci]" && git push')
      end

      private

      def get_branch
        run_command('git branch --show-current').strip
      end

      def guard_main_branch(branch)
        raise 'Cannot run on main branch' if branch == 'main'
      end

      def trigger_workflow(branch)
        @gh.run("workflow run dude.yml --ref #{branch}")
      end

      def get_run_id
        list_cmd = 'run list --workflow=dude.yml --limit 1 --json databaseId'
        @gh.run("#{list_cmd} -q '.[0].databaseId'").strip
      end

      def wait_for_completion(run_id)
        Helpers::Wait.new.until do
          is_completed?(run_id)
        end
      end

      def is_completed?(run_id)
        status = @gh.run("run view #{run_id} --json status -q .status").strip
        status == 'completed'
      end

      def extract_repo_from_remote
        remote = run_command('git remote get-url origin').strip
        remote.match(%r{github\.com[:/](.+?)(?:\.git)?$})[1]
      end

      def check_workflow_success(run_url)
        cmd = "run view #{run_url.split('/')[-1]} --json conclusion " \
              "-q .conclusion"
        conclusion = @gh.run(cmd).strip
        raise "Workflow failed: #{run_url}" unless conclusion == 'success'
      end

      def find_and_select_pr(branch, run_url)
        pr_urls = fetch_prs(branch, run_url)
        warn_multiple_prs(pr_urls) if pr_urls.length > 1
        pr_urls.last
      end

      def fetch_prs(branch, run_url)
        prs_cmd = "pr list --head #{branch} --state open --json url " \
                  "-q '.[].url'"
        prs = @gh.run(prs_cmd).strip
        raise "No PR found: #{run_url}" if prs.empty?

        prs.split("\n")
      end

      def warn_multiple_prs(pr_urls)
        puts 'Multiple PRs found, using newest' if pr_urls.length > 1
      end

      def run_command(cmd)
        `#{cmd}`
      end
    end
  end
end
