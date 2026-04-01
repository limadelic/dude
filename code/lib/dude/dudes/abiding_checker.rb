module Dude
  module Dudes
    class AbidingChecker
      def initialize(pids_resolver)
        @pids_resolver = pids_resolver
      end

      def is_abiding?(pid, dude_dir, target)
        return false if pid.nil?

        child_tasks = find_child_tasks(pid)
        child_tasks.any? { |t| ::Dude::Dudes::TaskMatcher.new(@pids_resolver).matches?(t, dude_dir, target) }
      end

      private

      def find_child_tasks(pid)
        ::Dude::Helpers::BackgroundTasks.list.select { |t| ::Dude::Dudes::ProcessTree.new.has_ancestor?(t[:parent_pid], pid) }
      end
    end
  end
end
