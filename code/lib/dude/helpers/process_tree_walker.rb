module Dude
  module Helpers
    class ProcessTreeWalker
      def initialize
        @children_cache = {}
        @command_cache = {}
      end

      def descendants_with_parents(pids)
        descendants, parent_map = [], {}
        queue = pids.dup
        queue.each { |pid| build_tree(pid, descendants, parent_map) }
        [descendants, parent_map]
      end

      def command_for(pid)
        @command_cache[pid] ||= `ps -o command= -p #{pid}`.strip
      end

      private

      def build_tree(pid, descendants, parent_map)
        children_of(pid).each do |child|
          descendants << child
          parent_map[child] = pid
          build_tree(child, descendants, parent_map)
        end
      end

      def children_of(pid)
        @children_cache[pid] ||= begin
          output = `pgrep -P #{pid}`.strip
          output.empty? ? [] : output.lines.map(&:strip).map(&:to_i)
        end
      end
    end
  end
end
