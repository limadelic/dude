module Dude
  module Transcript
    class ScannerSpawner
      def initialize(cache_path)
        @cache_path = cache_path
        @lock_path = "#{cache_path}.lock"
      end

      def spawn
        return false if lock_held?

        spawn_process
      end

      private

      def spawn_process
        do_spawn
      rescue StandardError
        false
      end

      def do_spawn
        pid = Process.spawn(
          'dude', 'transcript', 'scan',
          out: File::NULL, err: File::NULL
        )
        Process.detach(pid)
        write_lock(pid)
        true
      end

      def write_lock(pid)
        File.write(@lock_path, pid.to_s)
      end

      def lock_held?
        return false unless File.exist?(@lock_path)

        pid = read_lock_pid
        return false if pid.nil? || pid == 0

        process_alive?(pid)
      end

      def read_lock_pid
        File.read(@lock_path).to_i
      rescue StandardError
        nil
      end

      def process_alive?(pid)
        Process.kill(0, pid)
        true
      rescue Errno::ESRCH
        false
      end
    end
  end
end
