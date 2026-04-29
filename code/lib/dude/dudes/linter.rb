module Dude
  module Dudes
    class Linter
      COMMANDS = {
        ruby: ->(files) { "bundle exec rubocop #{files.join(' ')}" },
        elixir: ->(files) { "mix credo #{files.join(' ')}" },
        dotnet: ->(_files) { "dotnet format --verify-no-changes" },
        node: ->(_files) { "npm run lint" }
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
