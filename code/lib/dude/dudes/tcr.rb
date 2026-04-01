require_relative 'tests_runner'
require_relative 'linter'
require_relative 'git_stage_commit'
require_relative 'git_revert'

module Dude
  module Dudes
    class Tcr
      def initialize(files)
        @files = files
      end

      def run
        pass = rubocop_pass? && rspec_pass?
        pass ? commit : revert
        pass
      end

      private

      def rspec_pass?
        TestsRunner.new(@files).pass?
      end

      def rubocop_pass?
        Linter.new(@files).pass?
      end

      def commit
        GitStageCommit.new(@files).execute
      end

      def revert
        GitRevert.new(@files).execute
      end
    end
  end
end
