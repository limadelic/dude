require 'open3'

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
      'abide'  => [->(_) { ABIDE }, true],
      'tell'   => [->(c) { "dude #{c}; dude abide; #{ABIDE}" }, true],
      'abided' => [->(c) { "dude #{c}; #{ABIDE}" }, true]
    }

    def claude(home, cmd: 'tail -f /dev/null', replace: false)
      kill_for(home) if replace
      full_cmd = cmd.include?('&') ? "exec -a dude_test sh -c '#{cmd}'" : "exec -a dude_test #{cmd}"
      @sessions ||= {}
      @sessions[home] = spawn(full_cmd, chdir: home, pgroup: true, **DEV_NULL)
    end

    def run(home, command)
      verb = command.split.first
      builder, replace = RUNNERS[verb] || DEFAULT_RUNNER
      claude(home, cmd: builder.call(command), replace: replace)
    end

    def kill_for(home)
      @sessions ||= {}
      pid = @sessions.delete(home)
      return unless pid
      Process.kill('TERM', -pid) rescue nil
      Process.wait(pid) rescue nil
    end

    def wait_for(description, timeout: 10, interval: 0.2)
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
      (@sessions || {}).each_value do |pid|
        Process.kill('TERM', -pid) rescue nil
        Process.wait(pid) rescue nil
      end
    end

    def setup_from_row(row)
      @home = home(row['home'])
      row['abide'] == 'yes' ? setup_with_abide(row) : setup_without_abide(row)
    end

    def setup_with_abide(row)
      FileUtils.mkdir_p(@home)
      File.write(File.join(@home, 'CLAUDE.md'), "---\nicon: #{row['icon']}\n---\n")
      dude('pub', row['home'], chdir: @home)
      claude(@home, cmd: "dude abide & tail -f /dev/null")
    end

    def setup_without_abide(row)
      setup(@home, row["icon"])
      dude('pub', row['home'], chdir: @home) if row['pub'] == 'yes'
    end

    def dude(*args, stdin: nil, chdir: nil)
      cmd = "dude #{args.join(' ')}"
      opts = build_command_options(stdin, chdir)
      execute_dude_command(cmd, opts)
    end

    def build_command_options(stdin, chdir)
      opts = { stdin_data: stdin.to_s }
      opts[:chdir] = chdir if chdir
      opts
    end

    def execute_dude_command(cmd, opts)
      output, _, status = Open3.capture3(cmd, **opts)
      raise "CLI failed: #{cmd}" unless status.success?
      output
    end
  end
end
