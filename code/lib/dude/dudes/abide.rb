require_relative './inbox'
require_relative '../helpers/background_tasks'
require_relative '../helpers/wait'
require 'json'

module Dude
  module Dudes
    class Abide
      def initialize(inbox:, dude_dir:, name: nil, wait_helper: ::Dude::Helpers::Wait.new)
        @inbox = inbox
        @dude_dir = dude_dir
        @name = name
        @wait_helper = wait_helper
      end

      def launch
        kill_duplicate_abides
        msg = nil
        @wait_helper.until { msg = watch }
        msg.to_json
      end

      def watch
        msg = @inbox.first_new
        return nil unless msg

        @inbox.mark_wip
        msg
      end

      def tell(name, text)
        path = resolve_inbox(name)
        msg = { 'text' => text, 'status' => 'new' }
        inbox = inbox_for(path)
        inbox.append(msg)
      end

      def ask(name, text)
        path = resolve_inbox(name)
        msg = { 'from' => @name, 'text' => text, 'status' => 'new' }
        inbox = inbox_for(path)
        inbox.append(msg)
      end

      def abided(from: nil, reply: nil)
        reply_to(from, reply) if from && reply
        @inbox.mark_wip
        @inbox.dequeue_wip
      end

      def reply(to: nil, msg: nil)
        reply_to(to, msg) if to && msg
        @inbox.mark_wip
        @inbox.dequeue_wip
      end

      private

      def reply_to(from, reply)
        inbox = inbox_for(resolve_inbox(from))
        inbox.append({ 'from' => @name, 'text' => reply, 'status' => 'new' })
      end

      def resolve_inbox(name)
        @resolved ||= {}
        @resolved[name] ||= inbox_path_for(name)
      end

      def inbox_path_for(name)
        link = File.join(::Dude::GLOBAL_DIR, name)
        raise "dude '#{name}' not found" unless File.symlink?(link)

        target = File.readlink(link).chomp('/')
        File.join(target, 'dudes', 'inbox.json')
      end

      def inbox_for(path)
        @inboxes ||= {}
        @inboxes[path] ||= ::Dude::Dudes::Inbox.new(path)
      end

      def kill_duplicate_abides
        ::Dude::Helpers::BackgroundTasks.list
          .reject { |t| t[:pid] == Process.pid }
          .select { |t| t[:command].include?('dude abide') }
          .each { |t| ::Dude::Helpers::BackgroundTasks.kill(t[:pid]) }
      end
    end
  end
end
