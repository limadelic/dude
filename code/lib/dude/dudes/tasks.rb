require 'json'

module Dude
  module Dudes
    class Tasks
      def has_abide?(dude_dir)
        tasks_dir = find_tasks_dir(dude_dir)
        return false unless tasks_dir && Dir.exist?(tasks_dir)

        any_abide_task?(tasks_dir)
      rescue
        false
      end

      private

      def any_abide_task?(dir)
        Dir.children(dir).any? { |f| f.end_with?('.json') && abide?(dir, f) }
      end

      def abide?(dir, filename)
        task = JSON.load_file(File.join(dir, filename)) rescue nil
        task&.dig('subject')&.start_with?('Abide')
      end

      def find_tasks_dir(dude_dir)
        project_dir = project_dir_for(dude_dir)
        return nil unless Dir.exist?(project_dir)

        session_dir(project_dir)
      end

      def project_dir_for(dude_dir)
        encoded = File.dirname(dude_dir).gsub(/[\/.]/, '-')
        File.join(File.expand_path('~/.claude/projects'), encoded)
      end

      def session_dir(project_dir)
        jsonl = latest_jsonl(project_dir)
        return nil unless jsonl

        File.join(
          File.expand_path('~/.claude/tasks'),
          File.basename(jsonl, '.jsonl')
        )
      end

      def latest_jsonl(project_dir)
        Dir.children(project_dir)
          .select { |f| f.end_with?('.jsonl') }
          .map { |f| File.join(project_dir, f) }
          .max_by { |f| File.mtime(f) }
      end
    end
  end
end
