require_relative '../status_line/format'
require_relative '../dudes'
require_relative 'registry'
require_relative 'abide'
require_relative 'home'
require_relative 'health'
require_relative 'tasks'
require 'json'

class Dudes::Renderer
  include StatusLine::Format

  def initialize(session, dudes_override, cwd, fs, context_percentage)
    @session, @dudes = session, dudes_override
    @cwd, @fs, @context_percentage = cwd, fs, context_percentage
  end

  def render
    dudes = @dudes || load_dudes
    dudes.empty? ? nil : dudes.map { |d| dude_display(d) }.join(' ') rescue nil
  end

  def write_status
    return unless @fs.dir_exist?(dude_dir)
    existing = read_status
    color = context_color
    sync_session_color(color, existing['color'])
    merged = existing.merge('context' => @context_percentage, 'color' => color)
    @fs.write(status_path, merged.to_json) rescue nil
  end

  private

  def dude_display(d)
    color = color_for_pct(d[:context] || 0)
    emoji_group(d[:icon], d[:abide_dead] ? 'ˣ' : d[:messages], d[:current], color)
  end

  def load_dudes
    loader = Dudes::Home.new(@fs)
    names = loader.list_dude_names(root_dude_dir)
    raw_dudes = names.filter_map { |name| load_single_dude(loader, name) }
    registry = Dudes::Registry.new(@fs, @cwd, @context_percentage)
    registry.load(raw_dudes)
  end

  def load_single_dude(loader, name)
    target = loader.read_dude_link(root_dude_dir, name)
    return nil unless target
    data = loader.read_dude_data(target)
    return nil unless data
    data.merge(name: name, abide_dead: check_dead(data))
  end

  def check_dead(data)
    h = Dudes::Health.new(@fs).check(data[:dude_dir], data[:status])
    has_task = Dudes::Tasks.new(@fs).has_abide?(data[:dude_dir])
    Dudes::Abide.new.dead?(h[:pids], h[:pid_alive], data[:inbox], has_task)
  end

  def context_color
    @context_percentage < 33 ? 'green' : (@context_percentage <= 66 ? 'yellow' : 'red')
  end

  def sync_session_color(color, previous)
    return if color == previous
    system('osascript', '-e', "tell application \"System Events\"\nkeystroke \"/color #{color}\"\nkeystroke return\nend tell")
  end

  def read_status
    JSON.parse(@fs.read(status_path)) rescue {}
  end

  def status_path
    File.join(dude_dir, 'status.json')
  end

  def claude_dir
    @claude_dir ||= (c = File.expand_path('.claude', @cwd); @fs.dir_exist?(c) ? c : @cwd)
  end

  def dude_dir
    File.join(claude_dir, 'dudes')
  end

  def root_dude_dir
    File.join(File.expand_path('~/.claude'), 'dudes')
  end
end
