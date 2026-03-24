require_relative '../dudes'

class Dudes::Registry
  def initialize(fs, cwd, context_percentage)
    @fs, @cwd, @context_percentage = fs, cwd, context_percentage
  end

  def load(dudes_data)
    dudes_data.map { |d| build_dude_record(d) }
  end

  private

  def build_dude_record(data)
    current = is_current?(data[:target])
    ctx = current ? @context_percentage : (data[:status]['context'] || 0)
    {
      name: data[:name],
      icon: data[:icon],
      messages: data[:inbox].length,
      context: ctx,
      current: current,
      abide_dead: data[:abide_dead] || false
    }
  end

  def is_current?(target)
    normalize_path(target) == normalize_path(compute_claude_dir)
  end

  def normalize_path(path)
    path.chomp('/')
  end

  def compute_claude_dir
    @claude_dir ||= @cwd.end_with?('/.claude') ? @cwd : resolve_claude_dir
  end

  def resolve_claude_dir
    c = File.expand_path('.claude', @cwd)
    @fs.dir_exist?(c) ? c : @cwd
  end
end
