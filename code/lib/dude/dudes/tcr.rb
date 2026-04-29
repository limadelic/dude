require_relative 'tests_runner'
require_relative 'linter'
require_relative 'git_stage_commit'
require_relative 'git_revert'
require_relative 'platform_detector'

module Dude
  module Dudes
    class Tcr
      def initialize(files)
        @files = files
      end

      def run
        platform = PlatformDetector.detect(@files)
        pass = tests_pass?(platform) && lint_pass?(platform)
        pass ? commit : revert
        pass
      end

      private

      def tests_pass?(platform)
        TestsRunner.new(@files, platform).pass?
      end

      def lint_pass?(platform)
        Linter.new(@files, platform).pass?
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
