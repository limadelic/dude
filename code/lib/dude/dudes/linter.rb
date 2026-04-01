module Dude
  module Dudes
    class Linter
      def initialize(files)
        @files = files
      end

      def pass?
        system("bundle exec rubocop #{@files.join(' ')} > /dev/null 2>&1")
      end
    end
  end
end
