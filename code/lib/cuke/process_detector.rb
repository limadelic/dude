module Cuke
  class ProcessDetector
    def self.visible_with_cwd?(home)
      new(home).visible?
    end

    def initialize(home)
      @home = home
      @real_home = resolve_real_path(home)
    end

    def visible?
      get_dude_processes.any? { |line| matches_home?(line) }
    end

    private

    def get_dude_processes
      pgrep_output = `pgrep -a dude_test 2>/dev/null`.strip
      pgrep_output.empty? ? [] : pgrep_output.split("\n")
    end

    def matches_home?(line)
      pid = extract_pid(line)
      return false unless pid&.positive?

      lsof_output = `lsof -p #{pid} 2>/dev/null`
      cwd = extract_cwd(lsof_output)
      match_path?(cwd)
    end

    def extract_pid(line)
      line.split.first&.to_i
    end

    def extract_cwd(lsof_output)
      lsof_output[/cwd\s+DIR\s+\S+\s+\S+\s+\S+\s+(.+)/, 1]
    end

    def match_path?(cwd)
      return false unless cwd

      real_cwd = resolve_real_path(cwd)
      normalized_path(real_cwd) == normalized_path(@real_home)
    end

    def resolve_real_path(path)
      File.realpath(File.expand_path(path))
    rescue StandardError
      File.expand_path(path)
    end

    def normalized_path(path)
      path.chomp('/')
    end
  end
end
