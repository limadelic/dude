require_relative '../helpers/gh'

module Dude
  module News
    class GithubSource
      def initialize(gh: Dude::Helpers::Gh.new)
        @gh = gh
      end

      def latest_version
        cmd = "release list -R anthropics/claude-code --limit 1 --json tagName -q '.[0].tagName'"
        @gh.run(cmd)
      end

      def workflow_conclusion
        cmd = "run list --repo UKGEPIC/dude --branch main --limit 1 --json conclusion -q '.[0].conclusion'"
        @gh.run(cmd)
      end

      def run_url
        id = @gh.run(run_id_cmd)
        id.empty? ? nil : "https://github.com/UKGEPIC/dude/actions/runs/#{id}"
      end

      def releases(limit)
        output = @gh.run(releases_cmd(limit))
        output.split("\n").reject(&:empty?)
      end

      private

      def run_id_cmd
        "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
      end

      def releases_cmd(limit)
        "release list -R anthropics/claude-code --limit #{limit} --json tagName -q '.[].tagName'"
      end
    end
  end
end
