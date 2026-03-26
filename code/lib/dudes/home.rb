require_relative '../helpers/json'
require_relative './inbox'

class Dude::Dudes::Home
  include Helpers::Json

  def list_dude_names(dir)
    Dir.children(dir).select { |n| File.symlink?(File.join(dir, n)) }
  rescue
    []
  end

  def read_dude_link(dudes_dir, name)
    link_path = File.join(dudes_dir, name)
    return nil unless File.symlink?(link_path)
    target = expand_target(File.readlink(link_path), dudes_dir)
    is_accessible?(target) ? target : nil
  end

  def read_dude_data(target)
    icon = read_icon(File.join(target, 'CLAUDE.md'))
    return nil unless icon
    status = read_json(File.join(target, 'dudes', 'status.json')) || {}
    inbox_path = File.join(target, 'dudes', 'inbox.json')
    inbox = Dude::Dudes::Inbox.new(inbox_path)
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
    Dude::Dudes.pids.any? { |_pid, cwd| cwd == target || File.dirname(target) == cwd }
  end
end
