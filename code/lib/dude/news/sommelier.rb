require_relative '../helpers/gh'

module Dude
  module News
    class Sommelier
      def initialize(gh: Dude::Helpers::Gh.new)
        @gh = gh
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

      private

      def run_id_cmd
        opts = "--json databaseId -q '.[0].databaseId'"
        "run list --repo UKGEPIC/dude --branch main --limit 1 #{opts}"
      end
    end
  end
end
