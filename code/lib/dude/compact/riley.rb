module Dude
  module Compact
    class Riley
      FORK = /\s*⑂\s*(.+)\z/
      LINE = /\A-\s*Riley:/i

      def initialize(silo, cwd)
        @silo = silo
        @cwd = cwd
      end

      def line
        File.read(path).split("\n").find { |text| text.match?(LINE) }&.strip
      rescue Errno::ENOENT
        nil
      end

      private

      def path
        File.join(@cwd, file)
      end

      def file
        fork = @silo[FORK, 1]
        fork ? "CLAUDE.local.#{fork}.md" : 'CLAUDE.local.md'
      end
    end
  end
end
