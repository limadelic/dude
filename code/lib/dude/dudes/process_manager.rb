module Dude
  module Dudes
    class ProcessManager
      def self.kill_watchers
        pids = pgrep_all('dude abide')
        pids.each { |pid| kill_process(pid) }
      end

      def self.pgrep_all(pattern)
        result = `pgrep -f "#{pattern}"`.strip.split("\n")
        result.map(&:to_i).select(&:positive?)
      end

      def self.kill_process(pid)
        Process.kill('TERM', pid) rescue nil
      end
    end
  end
end
