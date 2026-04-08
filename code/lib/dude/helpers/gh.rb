module Dude
  module Helpers
    class Gh
      def self.create
        new
      end

      def run(cmd)
        `gh #{cmd}`.strip
      end
    end
  end
end
