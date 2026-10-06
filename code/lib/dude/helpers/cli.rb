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

    class TranscriptCommand < Thor
      desc "scan", "Scan transcripts and update usage cache"
      def scan
        run_scan_with_cleanup
      end

      private

      def run_scan_with_cleanup
        safe_perform_scan
      ensure
        remove_lock_file
      end

      def safe_perform_scan
        load_transcript_dependencies
        perform_scan
      rescue StandardError => e
        handle_scan_error(e)
      end

      def load_transcript_dependencies
        require_relative '../transcript/usage_cache_store'
        require_relative '../transcript/usage_scanner'
        require_relative '../status_line/price_table'
      end

      def perform_scan
        cache = load_cache
        scan_and_save(cache)
      end

      def load_cache
        cache_store = Dude::Transcript::UsageCacheStore.new
        cache_store.load(Dude::StatusLine::PriceTable.new)
      end

      def scan_and_save(cache)
        scanner = Dude::Transcript::UsageScanner.new
        paths = Dir.glob(File.expand_path('~/.claude/**/*.jsonl'))
        scanner.scan(cache, paths, ['5h', '7d'])
        Dude::Transcript::UsageCacheStore.new.save(cache)
        puts "scan complete"
      end

      def handle_scan_error(error)
        puts "scan error: #{error.message}"
      end

      def remove_lock_file
        lock_path = File.expand_path('~/.claude/dude/usage_cache.json.lock')
        File.delete(lock_path) if File.exist?(lock_path)
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

      desc "news [OPTIONS]", "Report on latest Claude Code releases"
      option :limit, type: :numeric, default: 5,
        desc: "Number of releases to show"
      def news
        require_relative '../news/news'
        Dude::News::News.new(limit: options[:limit]).run
      end

      desc "alley-pr", "Create PR for current branch"
      def alley_pr
        require_relative '../dudes/alley_pr'
        result = Dude::Dudes::AlleyPr.new.execute
        puts result
      rescue StandardError => e
        puts e.message
      end

      desc "dudes", "Manage dudes"
      subcommand :dudes, DudesCommand

      desc "background_tasks", "Manage background tasks"
      subcommand :background_tasks, BackgroundTasksCommand

      desc "transcript", "Manage transcripts"
      subcommand :transcript, TranscriptCommand

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
