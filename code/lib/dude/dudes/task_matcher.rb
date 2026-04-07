module Dude
  module Dudes
    class TaskMatcher
      def initialize(pids_resolver)
        @pids_resolver = pids_resolver
      end

      def matches?(task, dude_dir, target)
        cmd = task[:command]
        return cmd.include?(dude_dir) if cmd.include?('/.claude/dudes')
        return @pids_resolver.call(target).any? if cmd.include?('dude abide')

        cmd.include?("wait-until") && cmd.include?(
          File.join(
            dude_dir,
            'inbox.json'
          )
        )
      end
    end
  end
end
