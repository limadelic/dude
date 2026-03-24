require_relative '../helpers/json'
require_relative '../dudes'

class Dudes::Tasks
  include Helpers::Json

  def initialize(fs)
    @fs = fs
  end

  def has_abide?(dude_dir)
    tasks_dir = find_tasks_dir(dude_dir)
    return false unless tasks_dir && @fs.dir_exist?(tasks_dir)
    any_abide_task?(tasks_dir)
  rescue
    false
  end

  private

  def any_abide_task?(dir)
    @fs.children(dir).any? { |f| f.end_with?('.json') && abide?(dir, f) }
  end

  def abide?(dir, filename)
    task = read_json(File.join(dir, filename)) || {}
    task['subject']&.start_with?('Abide')
  end

  def find_tasks_dir(dude_dir)
    project_dir = project_dir_for(dude_dir)
    return nil unless @fs.dir_exist?(project_dir)
    session_dir(project_dir)
  end

  def project_dir_for(dude_dir)
    encoded = File.dirname(dude_dir).gsub(/[\/.]/, '-')
    File.join(File.expand_path('~/.claude/projects'), encoded)
  end

  def session_dir(project_dir)
    jsonl = @fs.newest_child(project_dir, '.jsonl')
    return nil unless jsonl
    File.join(File.expand_path('~/.claude/tasks'), File.basename(jsonl, '.jsonl'))
  end
end
