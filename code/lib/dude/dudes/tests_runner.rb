module Dude
  module Dudes
    class TestsRunner
      COMMANDS = {
        ruby: ->(files) { "bundle exec rspec #{files.join(' ')}" },
        elixir: ->(files) { "mix test #{files.join(' ')}" },
        dotnet: ->(_files) { "dotnet test" },
        node: ->(_files) { "npm test" }
      }

      def initialize(files, platform = :ruby)
        @files = files
        @platform = platform
      end

      def pass?
        command = COMMANDS[@platform].call(@files)
        system("#{command} > /dev/null 2>&1")
      end
    end
  end
end
