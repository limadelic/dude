module Dude
  module Dudes
    class ProcessTree
      def self.is_current?(pid)
        new.is_current?(pid)
      end

      def is_current?(pid)
        return false unless pid

        walk_ancestors(Process.ppid) { |p| return true if p == pid }
        false
      end

      def has_ancestor?(check_pid, target_pid)
        walk_ancestors(check_pid) { |p| return true if p == target_pid }
        false
      end

      private

      def walk_ancestors(pid)
        loop do
          yield pid
          return if pid == 1 || (next_pid = parent_pid(pid)) == pid

          pid = next_pid
        end
      end

      def parent_pid(pid)
        @parent_pids ||= {}
        @parent_pids[pid] ||= fetch_parent_pid(pid)
      end

      def fetch_parent_pid(pid)
        return shell_parent_pid(pid) unless File.exist?("/proc/#{pid}/stat")

        File.read("/proc/#{pid}/stat").split[3].to_i
      rescue
        pid
      end

      def shell_parent_pid(pid)
        `ps -o ppid= -p #{pid} 2>/dev/null`.strip.to_i
      end
    end
  end
end
