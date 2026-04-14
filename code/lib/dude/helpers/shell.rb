module Dude
  module Helpers
    class Shell
      def self.create
        new
      end

      def run(cmd)
        `#{cmd}`.strip
      end
    end
  end
end
