require_relative '../helpers/json'
require_relative '../dudes'

class Dudes::Home
  include Helpers::Json

  def initialize(fs)
    @fs = fs
  end

  def list_dude_names(dir)
    @fs.children(dir).select { |n| @fs.symlink?(File.join(dir, n)) }
  rescue
    []
  end

  def read_dude_link(dudes_dir, name)
    link_path = File.join(dudes_dir, name)
    return nil unless @fs.symlink?(link_path)
    target = expand_target(@fs.readlink(link_path), dudes_dir)
    is_accessible?(target) ? target : nil
  end

  def read_dude_data(target)
    icon = read_icon(File.join(target, 'CLAUDE.md'))
    return nil unless icon
    status = read_json(File.join(target, 'dudes', 'status.json')) || {}
    inbox = read_json(File.join(target, 'dudes', 'inbox.json')) || []
    { icon: icon, target: target, status: status, inbox: inbox, dude_dir: File.join(target, 'dudes') }
  end

  private

  def expand_target(readlink_result, dudes_dir)
    path = readlink_result.chomp('/')
    return path if path.start_with?('/')

    parts = dudes_dir.split('/').reject(&:empty?)
    path.split('/').each do |component|
      if component == '..'
        parts.pop
      elsif component != '.'
        parts << component
      end
    end
    '/' + parts.join('/')
  end

  def is_accessible?(target)
    @fs.claude_cwds.any? { |c| c == target || File.dirname(target) == c }
  end
end
