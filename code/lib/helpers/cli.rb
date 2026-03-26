require 'thor'
require 'json'

module Dude
  class DudesCommand < Thor
    desc "list", "List all dudes"
    def list
      require 'json'
      require_relative '../dudes/dudes'
      puts JSON.generate(dudes.all.map(&:to_h))
    end

    private

    def dudes
      @dudes ||= Dude::Dudes.new
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

  class CLI < Thor
    desc "status_line", "Render status line"
    def status_line
      require_relative '../status_line/runner'
      input = STDIN.read
      input = '{}' if input.strip.empty?
      StatusLine::Runner.new(input, dudes: Dude::Dudes.new.all).run
    end

    desc "pub [NAME]", "Register as a pub dude"
    def pub(name = nil)
      require_relative '../dudes/dudes'
      dude = dudes.current
      raise "No dude running for #{Dir.pwd}" unless dude
      result = dude.pub(name)
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
      require_relative '../dudes/dudes'
      dude = dudes.current
      raise "No dude running" unless dude
      dude.tell(name, words.join(' '))
      puts "tell → #{name}"
    end

    desc "ask NAME MESSAGE", "Ask a dude something"
    def ask(name, *words)
      require_relative '../dudes/dudes'
      dude = dudes.current
      raise "No dude running" unless dude
      dude.ask(name, words.join(' '))
      puts "ask → #{name}"
    end

    desc "abide", "Watch inbox and return first message"
    def abide
      require_relative 'background_tasks'
      require_relative '../dudes/dudes'
      require_relative 'wait'

      others = BackgroundTasks.list
        .reject { |t| t[:pid] == Process.pid }
        .select { |t| t[:command].include?('dude abide') }

      if others.any?
        others.each { |t| BackgroundTasks.kill(t[:pid]) }
        return
      end

      dude = dudes.current
      raise "No dude running" unless dude
      msg = nil
      Helpers::Wait.new.until { msg = dude.watch }
      puts msg.to_json
    end

    desc "abided [FROM] [REPLY]", "Dequeue wip, optionally reply"
    def abided(from = nil, reply = nil)
      require_relative '../dudes/dudes'
      dude = dudes.current
      raise "No dude running" unless dude
      dude.abided(from: from, reply: reply)
    end

    desc "dudes", "Manage dudes"
    subcommand :dudes, DudesCommand

    desc "background_tasks", "Manage background tasks"
    subcommand :background_tasks, BackgroundTasksCommand

    private

    def dudes
      @dudes ||= Dude::Dudes.new
    end
  end
end
