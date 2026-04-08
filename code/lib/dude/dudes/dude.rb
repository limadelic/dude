require 'json'
require_relative 'abide'
require_relative 'pub'
require_relative 'inbox'

module Dude
  module Dudes
    class Dude
      attr_reader :icon, :inbox, :status, :name, :target
      attr_accessor :pid

      def initialize(opts = {})
        init(opts)
        @registry = opts[:registry]
        @abide = ::Dude::Dudes::Abide.new(
          inbox: @inbox, dude_dir: @dude_dir,
          name: @name
        )
        @pub = ::Dude::Dudes::Pub.new(target: @target)
      end

      def is_current?
        return false unless @pid

        @registry.is_current?(@pid)
      end

      def is_abiding?
        @registry.is_abiding?(@pid, @dude_dir, @target)
      end

      def messages
        @inbox.length
      end

      def context
        @status['context'] || 0
      end

      def to_h
        {
          name: @name, icon: @icon, pid: @pid, current: is_current?,
          abiding: is_abiding?, target: @target,
          messages: messages, context: context
        }
      end

      def pids_for_target
        @registry.pids_for_target(@target)
      end

      def tell(name, text)
        @abide.tell(name, text)
      end

      def ask(name, text)
        @abide.ask(name, text)
      end

      def reply(to: nil, msg: nil)
        @abide.reply(to: to, msg: msg)
      end

      def pub(icon = nil)
        icon ||= @name
        @pub.pub(@target, icon)
      end

      def sub(name = nil)
        @pub.sub(@target, name)
      end

      def unpub
        @pub.unpub(@target)
      end

      def append(message)
        @inbox.append(message)
      end

      def first_new
        @inbox.first_new
      end

      def mark_wip
        @inbox.mark_wip
      end

      def dequeue_wip
        @inbox.dequeue_wip
      end

      def abide
        @abide.launch
      end

      def watch
        @abide.watch
      end

      def abided(from: nil, reply: nil)
        @abide.abided(from: from, reply: reply)
      end

      def finish(from: nil, reply: nil)
        abided(from: from, reply: reply)
      end

      private

      def init(opts)
        keys = %i[name icon inbox status dude_dir target]
        vals = opts.values_at(*keys)
        @name, @icon, @inbox, @status, @dude_dir, @target = vals
        @pid = nil
      end
    end
  end
end
