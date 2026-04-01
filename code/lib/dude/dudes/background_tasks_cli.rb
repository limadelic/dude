require_relative '../helpers/background_tasks'

module Dude
  module Dudes
    class BackgroundTasksCli
      def list
        tasks = ::Dude::Helpers::BackgroundTasks.list
        return puts "No background tasks" if tasks.empty?

        format_tasks(tasks)
      end

      def kill(pid)
        ::Dude::Helpers::BackgroundTasks.kill(pid.to_i)
      end

      private

      def format_tasks(tasks)
        tasks.each { |task| puts "#{task[:pid]} #{task[:command]}" }
      end
    end
  end
end
