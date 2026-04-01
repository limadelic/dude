require 'thor'
require 'json'

module Dude
  module Helpers
    class DudesCommand < Thor
      desc "list", "List all dudes"
      def list
        require 'json'
        require_relative '../dudes/dudes'
        puts JSON.generate(dudes.all.map(&:to_h))
      end

      private

      def dudes
        @dudes ||= Dude::Dudes::Dudes.new
      end
    end

    class BackgroundTasksCommand < Thor
      desc "list", "List all background tasks"
      def list
        require_relative '../dudes/background_tasks_cli'
        Dude::Dudes::BackgroundTasksCli.new.list
      end

      desc "kill PID", "Kill a background task"
      def kill(pid)
        require_relative '../dudes/background_tasks_cli'
        Dude::Dudes::BackgroundTasksCli.new.kill(pid)
      end
    end

    class Cli < Thor
      desc "status_line", "Render status line"
      def status_line
        require_relative '../status_line/runner'
        input = STDIN.read
        input = '{}' if input.strip.empty?
        Dude::StatusLine::Runner.new(input, dudes: Dude::Dudes::Dudes.new.all).run
      end

      desc "pomo", "Render pomo timer"
      def pomo
        require_relative '../pomo/pomo'
        puts Dude::Pomo::Pomo.new.to_s
      end

      desc "pub [NAME]", "Register as a pub dude"
      def pub(name = nil)
        require_relative '../dudes/dudes'
        require_relative '../dudes/pub'
        result = Dude::Dudes::Pub.new(target: Dir.pwd).pub(Dir.pwd, name)
        puts result
      end

      desc "sub [NAME]", "Register as a sub dude (private to nearest pub)"
      def sub(name = nil)
        require_relative '../dudes/dudes'
        dude = dudes.current
        raise "No dude running" unless dude

        result = dude.sub(name)
        puts result
      end

      desc "unpub", "Tear down all pub dudes"
      def unpub
        require_relative '../dudes/dudes'
        dude = dudes.current
        raise "No dude running" unless dude

        dude.unpub
        puts "clean"
      end

      desc "tell NAME MESSAGE", "Tell a dude something"
      def tell(name, *words)
        current_dude.tell(name, words.join(' '))
        puts "tell → #{name}"
      end

      desc "ask NAME MESSAGE", "Ask a dude something"
      def ask(name, *words)
        current_dude.ask(name, words.join(' '))
        puts "ask → #{name}"
      end

      desc "abide", "Watch inbox and return first message"
      def abide
        require 'json'
        puts current_dude.abide
      end

      desc "abided [FROM] [REPLY]", "Dequeue wip, optionally reply"
      def abided(from = nil, reply = nil)
        current_dude.abided(from: from, reply: reply)
      end

      desc "reply TO MESSAGE", "Reply to a dude"
      def reply(to, *words)
        current_dude.reply(to: to, msg: words.join(' '))
      end

      desc "tcr FILES", "Test && commit || revert"
      def tcr(*files)
        require_relative '../dudes/tcr'
        result = Dude::Dudes::Tcr.new(files).run
        exit(result ? 0 : 1)
      end

      desc "dudes", "Manage dudes"
      subcommand :dudes, DudesCommand

      desc "background_tasks", "Manage background tasks"
      subcommand :background_tasks, BackgroundTasksCommand

      private

      def current_dude
        require_relative '../dudes/dudes'
        dudes.current or raise "No dude running"
      end

      def dudes
        @dudes ||= Dude::Dudes::Dudes.new
      end
    end
  end
end
