require_relative '../dudes/dudes'

class BackgroundTasks
  def self.list
    @children = {}
    @commands = {}

    live_pids = Dude::Dudes.pids.keys
    return [] if live_pids.empty?

    descendants = []
    parent_map = {}
    queue = live_pids.dup

    while queue.any?
      pid = queue.shift
      children = find_children(pid)
      children.each do |child_pid|
        descendants << child_pid
        parent_map[child_pid] = pid
        queue << child_pid
      end
    end

    descendants.sort.map { |pid| { pid: pid, parent_pid: parent_map[pid], command: command_for_pid(pid) } }
  end

  def self.kill(pid)
    Process.kill('TERM', pid)
  end

  private

  def self.find_children(pid)
    @children ||= {}
    return @children[pid] if @children.key?(pid)

    output = `pgrep -P #{pid}`.strip
    result = output.empty? ? [] : output.lines.map(&:strip).map(&:to_i)
    @children[pid] = result
  end

  def self.command_for_pid(pid)
    @commands ||= {}
    return @commands[pid] if @commands.key?(pid)

    result = `ps -o command= -p #{pid}`.strip
    @commands[pid] = result
  end
end
