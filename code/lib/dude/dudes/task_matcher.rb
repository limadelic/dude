module Dude
  module Dudes
    class TaskMatcher
      def initialize(pids_resolver)
        @pids_resolver = pids_resolver
      end

      def matches?(task, dude_dir, target)
        cmd = task[:command]
        return cmd.include?(dude_dir) if cmd.include?('/.claude/dudes')
        return true if cmd.include?('dude abide') && @pids_resolver.call(target).any?
        cmd.include?("wait-until") && cmd.include?(File.join(dude_dir, 'inbox.json'))
      end
    end
  end
end