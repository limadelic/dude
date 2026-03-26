require_relative '../helpers/background_tasks'

module Dude
  GLOBAL_DIR = File.expand_path('~/.claude/dudes').freeze

class Dudes
  def self.pids
    @pids ||= `pgrep -a claude`.strip.split("\n").each_with_object({}) do |line, hash|
      pid = line.split.first&.to_i
      next unless pid&.positive?
      cwd = `lsof -p #{pid} 2>/dev/null`[/cwd\s+DIR\s+\S+\s+\S+\s+\S+\s+(.+)/, 1]
      hash[pid] = cwd if cwd
    end
  end

  def pids
    @pids ||= self.class.pids
  end

  def initialize
    @home = ::Dude::Dudes::Home.new
    @tasks = ::Dude::Dudes::Tasks.new
    @pids = nil  # Will be lazily initialized and memoized
    @parent_pids = {}  # Cache for parent_pid lookups
  end

  def all
    @all ||= load_all_with_pid_binding
  end

  def current
    all.find(&:is_current?)
  end

  def resolve_inbox(name)
    link = File.join(::Dude::GLOBAL_DIR, name)
    raise "dude '#{name}' not found" unless File.symlink?(link)
    target = File.readlink(link).chomp('/')
    File.join(target, 'dudes', 'inbox.json')
  end

  def read_self_name(dude_dir)
    status = File.join(dude_dir, 'status.json')
    JSON.load_file(status)['name']
  end

  def is_current?(pid)
    return false unless pid
    current_pid = Process.ppid
    loop do
      return true if current_pid == pid
      return false if current_pid == 1
      next_pid = parent_pid(current_pid)
      return false if next_pid == current_pid
      current_pid = next_pid
    end
  end

  def is_abiding?(pid, dude_dir, target)
    effective_pid = pid
    return false if effective_pid.nil?

    tasks = ::BackgroundTasks.list
    tasks
      .select { |t| has_ancestor_pid?(t[:parent_pid], effective_pid) }
      .any? { |t| matches_abide_task?(t, dude_dir, target) }
  end

  def pids_for_target(target)
    target_normalized = target.chomp('/')
    parent = File.dirname(target_normalized)
    pids.select { |_pid, cwd|
      c = cwd.chomp('/')
      c == target_normalized || c == parent
    }.keys
  end

  private

  def load_all_with_pid_binding
    names = @home.list_dude_names(::Dude::GLOBAL_DIR)
    template_dudes = names.filter_map { |name| build_dude(name) }
    expand_dudes_by_pid(template_dudes)
  end

  def expand_dudes_by_pid(template_dudes)
    require_relative './dude'
    result = []
    target_to_templates = template_dudes.group_by(&:target)

    target_to_templates.each do |_target, templates|
      # Get all PIDs for this target
      pids = pids_for_target(templates.first&.target) || []

      if pids.empty?
        # No running processes, keep original templates
        result.concat(templates)
      else
        # Create one dude entry per PID
        pids.each do |pid|
          # Use the first template as a base
          template = templates.first
          target = template.target
          data = @home.read_dude_data(target)
          next unless data

          # Create a new dude for this specific PID
          dude = ::Dude::Dudes::Dude.new(**data.merge(name: template.name, registry: self))
          dude.pid = pid
          result << dude
        end
      end
    end

    result
  end

  def build_dude(name)
    require_relative './dude'
    target = @home.read_dude_link(::Dude::GLOBAL_DIR, name)
    return nil unless target
    data = @home.read_dude_data(target)
    return nil unless data
    ::Dude::Dudes::Dude.new(**data.merge(name: name, registry: self))
  end

  def has_ancestor_pid?(check_pid, target_pid)
    current_pid = check_pid
    loop do
      return true if current_pid == target_pid
      return false if current_pid == 1
      next_pid = parent_pid(current_pid)
      return false if next_pid == current_pid
      current_pid = next_pid
    end
  end

  def matches_abide_task?(task, dude_dir, target)
    cmd = task[:command]

    # If it explicitly mentions a dude_dir, it must be this one
    if cmd.include?('/.claude/dudes')
      return cmd.include?(dude_dir)
    end

    # Check for "dude abide" (bare or wrapped) with target running
    return true if cmd.include?('dude abide') && pids_for_target(target).any?

    # Check for wait-until monitoring this dude's inbox
    return true if cmd.include?("wait-until") && cmd.include?(File.join(dude_dir, 'inbox.json'))

    false
  end

  def parent_pid(pid)
    @parent_pids ||= {}
    return @parent_pids[pid] if @parent_pids.key?(pid)

    result = fetch_parent_pid(pid)
    @parent_pids[pid] = result
    result
  end

  def fetch_parent_pid(pid)
    proc_path = "/proc/#{pid}/stat"
    return File.read(proc_path).split[3].to_i if File.exist?(proc_path)
    shell_parent_pid(pid)
  rescue
    pid
  end

  def shell_parent_pid(pid)
    output = `ps -o ppid= -p #{pid} 2>/dev/null`.strip
    output.to_i
  end
end
end

require_relative './home'
require_relative './tasks'
require_relative './inbox'
require_relative './dude'
