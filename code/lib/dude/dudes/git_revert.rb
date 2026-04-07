module Dude
  module Dudes
    class GitRevert
      def initialize(files)
        @files = files
      end

      def execute
        @files.each { |f| system("git checkout #{f}") }
      end
    end
  end
end
