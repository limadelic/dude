require_relative '../helpers/gh'

module Dude
  module News
    class GithubSource
      def initialize(gh: Dude::Helpers::Gh.new)
        @gh = gh
      end

      def latest_version
        opts = "--limit 1 --json tagName -q '.[0].tagName'"
        @gh.run("release list -R anthropics/claude-code #{opts}")
      end

      def workflow_conclusion
        opts = "--json conclusion -q '.[0].conclusion'"
        cmd = "run list --repo UKGEPIC/dude --branch main --limit 1 #{opts}"
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
        opts = "--json databaseId -q '.[0].databaseId'"
        "run list --repo UKGEPIC/dude --branch main --limit 1 #{opts}"
      end

      def releases_cmd(limit)
        opts = "--json tagName -q '.[].tagName'"
        "release list -R anthropics/claude-code --limit #{limit} #{opts}"
      end
    end
  end
end
