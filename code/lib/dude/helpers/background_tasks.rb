require_relative '../dudes/dudes'
require_relative 'process_tree_walker'

module Dude
  module Helpers
    class BackgroundTasks
      def self.list
        live_pids = Dude::Dudes::Dudes.pids.keys
        return [] if live_pids.empty?

        descendants, parent_map = walker.descendants_with_parents(live_pids)
        descendants.sort.map { |pid| task_hash(pid, parent_map) }
      end

      def self.kill(pid)
        Process.kill('TERM', pid)
      end

      private

      def self.task_hash(pid, parent_map)
        {
          pid: pid, parent_pid: parent_map[pid],
          command: walker.command_for(pid)
        }
      end

      def self.walker
        @walker ||= Dude::Helpers::ProcessTreeWalker.new
      end
    end
  end
end
