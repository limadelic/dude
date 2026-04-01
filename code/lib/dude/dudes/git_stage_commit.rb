module Dude
  module Dudes
    class GitStageCommit
      def initialize(files)
        @files = files
      end

      def execute
        @files.each { |f| system("git add #{f}") }
        system("git commit -m \"TCR: auto-commit\" 2>&1")
      end
    end
  end
end
