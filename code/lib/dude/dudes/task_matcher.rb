module Dude
  module Dudes
    class TaskMatcher
      def initialize(pids_resolver)
        @pids_resolver = pids_resolver
      end

      def matches?(task, dude_dir, target)
        cmd = task[:command]
        return cmd.include?(dude_dir) if cmd.include?('/.claude/dudes')

        if cmd.include?('dude abide')
          return @pids_resolver.call(target).any?
        end

        inbox_path = File.join(dude_dir, 'inbox.json')
        cmd.include?("wait-until") && cmd.include?(inbox_path)
      end
    end
  end
end
