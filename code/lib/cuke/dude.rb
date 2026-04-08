require 'open3'
require_relative 'process_detector'

module Cuke
  module Dude
    DUDE_HOMES = {
      dude: ->(dh) { File.join(dh, '..') },
      elita: ->(dh) { File.join(dh, '..', 'elita') }
    }
    DEV_NULL = { out: '/dev/null', err: '/dev/null' }
    def home(label)
      resolver = DUDE_HOMES[label.to_sym]
      resolver ? resolver.call(@dude_home) : label
    end

    def setup(home, icon)
      FileUtils.mkdir_p(home)
      File.write(File.join(home, 'CLAUDE.md'), "---\nicon: #{icon}\n---\n")
      claude(home)
    end

    ABIDE = 'dude abide & tail -f /dev/null'

    DEFAULT_RUNNER = [->(c) { "dude #{c} & wait" }, false]

    RUNNERS = {
      'abide' => [->(_) { ABIDE }, true],
      'tell' => [->(c) { "dude #{c}; #{ABIDE}" }, true],
      'ask' => [->(c) { "dude #{c}; #{ABIDE}" }, true],
      'reply' => [->(c) { "dude #{c}; #{ABIDE}" }, true],
      'abided' => [->(c) { "dude #{c}; #{ABIDE}" }, true]
    }

    def claude(home, cmd: 'tail -f /dev/null', replace: false)
      kill_for(home) if replace
      full_cmd = build_spawn_command(cmd)
      @sessions ||= {}
      @sessions[home] = spawn(full_cmd, chdir: home, pgroup: true, **DEV_NULL)
      wait_for_process_startup(home) if replace
    end

    def run(home, command)
      verb = command.split.first
      builder, replace = RUNNERS[verb] || DEFAULT_RUNNER
      claude(home, cmd: builder.call(command), replace: replace)
    end

    def cleanup
      (@sessions || {}).each_value do |pid|
        Process.kill('TERM', -pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end

    def setup_from_row(row)
      @home = home(row['home'])
      row['abide'] == 'yes' ? setup_with_abide(row) : setup_without_abide(row)
    end

    def dude(*args, stdin: nil, chdir: nil)
      cmd = "dude #{args.join(' ')}"
      opts = { stdin_data: stdin.to_s, chdir: chdir }.compact
      output, _, status = Open3.capture3(cmd, **opts)
      raise "CLI failed: #{cmd}" unless status.success?

      output
    end

    def wait_for(description, timeout: 10, interval: 0.2)
      deadline = Time.now + timeout
      return if poll_until_deadline(deadline, interval) { yield }

      raise "Timed out waiting for #{description}"
    end

    private

    def build_spawn_command(cmd)
      escaped_cmd = cmd.gsub("'", "'\\\\''")
      wrapper = cmd.include?('&') ? "sh -c '#{escaped_cmd}'" : cmd
      "exec -a dude_test #{wrapper}"
    end

    def wait_for_process_startup(home)
      wait_for("process startup for #{home}", timeout: 10, interval: 0.05) do
        ProcessDetector.visible_with_cwd?(home)
      end
    end

    def kill_for(home)
      @sessions ||= {}
      pid = @sessions.delete(home)
      return unless pid

      Process.kill('TERM', -pid) rescue nil
      Process.wait(pid) rescue nil
    end

    def poll_until_deadline(deadline, interval)
      until Time.now > deadline
        return true if yield

        sleep interval
      end
      false
    end

    def setup_with_abide(row)
      FileUtils.mkdir_p(@home)
      content = "---\nicon: #{row['icon']}\n---\n"
      File.write(File.join(@home, 'CLAUDE.md'), content)
      dude('pub', row['home'], chdir: @home)
      claude(@home, cmd: "dude abide & tail -f /dev/null")
    end

    def setup_without_abide(row)
      setup(@home, row["icon"])
      dude('pub', row['home'], chdir: @home) if row['pub'] == 'yes'
    end
  end
end
