module Dude
  module Dudes
    class PlatformDetector
      EXTENSION_MAP = {
        '.rb' => :ruby,
        '.ex' => :elixir,
        '.exs' => :elixir,
        '.cs' => :dotnet,
        '.ts' => :node,
        '.js' => :node
      }

      def self.detect(files)
        raise 'TCR requires at least one file' if files.empty?

        platforms = files.map { |file| platform_for(file) }

        validate_same_platform(platforms)

        platforms.first
      end

      private

      def self.platform_for(file)
        extension = File.extname(file)
        EXTENSION_MAP[extension] ||
          raise('TCR only supports .rb, .ex, .exs, .cs, .ts, .js files')
      end

      def self.validate_same_platform(platforms)
        return if platforms.uniq.size == 1

        raise 'TCR files must be the same platform'
      end
    end
  end
end
