module Dude
  module Dudes
    class TestsRunner
      def initialize(files)
        @files = files
      end

      def pass?
        system("bundle exec rspec #{@files.join(' ')} > /dev/null 2>&1")
      end
    end
  end
end
