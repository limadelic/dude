require 'open3'

module Cuke
  module DudeTestProcess
    DUDE_HOMES = {
      dude: ->(dh) { File.join(dh, '..') },
      elita: ->(dh) { File.join(dh, '..', 'elita') }
    }.freeze

    DEV_NULL = { out: '/dev/null', err: '/dev/null' }.freeze

    def resolve_home(label)
      resolver = DUDE_HOMES[label.to_sym]
      resolver ? resolver.call(@dude_home) : label
    end

    def setup_dude(home, icon)
      FileUtils.mkdir_p(home)
      File.write(File.join(home, 'CLAUDE.md'), "---\nicon: #{icon}\n---\n")
      claude(home)
    end

    def claude(home, cmd: 'tail -f /dev/null')
      full_cmd = cmd.include?('&') ? "exec -a dude_test sh -c '#{cmd}'" : "exec -a dude_test #{cmd}"
      @session_pids ||= []
      @session_pids << spawn(full_cmd, chdir: home, **DEV_NULL)
    end

    def wait_for(description, timeout: 5, interval: 0.2)
      deadline = Time.now + timeout
      return if poll_until_deadline(deadline, interval) { yield }
      raise "Timed out waiting for #{description}"
    end

    def poll_until_deadline(deadline, interval)
      until Time.now > deadline
        return true if yield
        sleep interval
      end
      false
    end

    def cleanup
      (@session_pids || []).each do |pid|
        Process.kill('TERM', pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end
  end
end
