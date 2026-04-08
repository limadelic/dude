require 'json'

module Dude
  module Dudes
    class Health
      def initialize
      end

      def check(dude_dir, status)
        pids = find_pids(dude_dir)
        pid_alive = resolve_pid(pids, dude_dir, status)
        { pids: pids, pid_alive: pid_alive }
      end

      private

      def find_pids(dude_dir)
        pattern = "wait-until.*#{File.join(dude_dir, 'inbox.json')}"
        pgrep_all(pattern)
      end

      def resolve_pid(pids, dude_dir, status)
        pid_alive = first_alive(pids)
        update_pid(dude_dir, status, pid_alive) if
          pid_changed?(pid_alive, status)
        pid_alive
      end

      def first_alive(pids)
        alive = nil
        pids.each { |pid| alive ||= check_one(pid) }
        alive
      end

      def check_one(pid)
        orphaned?(pid) ? (kill(pid); nil) : pid
      end

      def pgrep_all(pattern)
        result = `pgrep -f "#{pattern}"`.strip.split("\n")
        result.map(&:to_i).select(&:positive?)
      end

      def orphaned?(pid)
        `ps -p #{pid} -o ppid=`.strip.to_i == 1
      end

      def kill(pid)
        Process.kill('TERM', pid) rescue nil
      end

      def pid_changed?(pid_alive, status)
        pid_alive && pid_alive != status['abide_pid']
      end

      def update_pid(dude_dir, status, pid_alive)
        path = File.join(dude_dir, 'status.json')
        data = status.merge('abide_pid' => pid_alive)
        File.write(path, data.to_json) rescue nil
      end
    end
  end
end
