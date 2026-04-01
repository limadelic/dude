require_relative '../helpers/background_tasks'
require_relative './process_tree'
require_relative './task_matcher'
require_relative './inbox_resolver'
require_relative './abiding_checker'

module Dude
  GLOBAL_DIR = File.expand_path(ENV['DUDE_HOME'] || '~/.claude/dudes').freeze

  module Dudes
    class Dudes
      def self.pids
        cmd = `pgrep -a #{ENV['DUDE_PROCESS'] || 'claude'}`
        @pids ||= cmd.strip.split("\n").map { |line|
          extract_pid_cwd(line)
        }.compact.to_h
      end

      def self.extract_pid_cwd(line)
        pid = line.split.first&.to_i
        return nil unless pid&.positive?

        pattern = /cwd\s+DIR\s+\S+\s+\S+\s+\S+\s+(.+)/
        cwd = `lsof -p #{pid} 2>/dev/null`[pattern, 1]
        [pid, cwd] if cwd
      end

      def pids
        @pids ||= self.class.pids
      end

      def initialize
        @home = ::Dude::Dudes::Home.new
        @tasks = ::Dude::Dudes::Tasks.new
        @pids = nil
      end

      def all
        @all ||= load_all_with_pid_binding
      end

      def current
        all.find(&:is_current?)
      end

      def resolve_inbox(name)
        InboxResolver.new.resolve(name)
      end

      def read_self_name(dude_dir)
        status = File.join(dude_dir, 'status.json')
        JSON.load_file(status)['name']
      end

      def is_current?(pid)
        ProcessTree.is_current?(pid)
      end

      def is_abiding?(pid, dude_dir, target)
        checker = AbidingChecker.new(method(:pids_for_target))
        checker.is_abiding?(pid, dude_dir, target)
      end

      def pids_for_target(target)
        normalized = target.chomp('/')
        pids.select { |_, cwd|
          cwd.chomp('/') == normalized ||
            File.dirname(normalized) == cwd.chomp('/')
        }.keys
      end

      private

      def load_all_with_pid_binding
        names = @home.list_dude_names(::Dude::GLOBAL_DIR)
        template_dudes = names.filter_map { |name| build_dude(name) }
        expand_dudes_by_pid(template_dudes)
      end

      def expand_dudes_by_pid(templates)
        require_relative './dude'
        templates.group_by(&:target).flat_map { |target, group|
          pids_for_target(target).empty? ? group : build_pids_dudes(
            group,
            target
          )
        }
      end

      def build_pids_dudes(templates, target)
        result = []
        add_dudes_for_pids(templates, target, result)
        result
      end

      def add_dudes_for_pids(templates, target, result)
        data = @home.read_dude_data(target)
        return unless data

        pids_for_target(target).each { |pid|
          result << new_dude_for_pid(templates, data, pid)
        }
      end

      def new_dude_for_pid(templates, data, pid)
        opts = data.merge(name: templates.first.name, registry: self)
        dude = ::Dude::Dudes::Dude.new(opts)
        dude.pid = pid
        dude
      end

      def build_dude(name)
        require_relative './dude'
        target = @home.read_dude_link(::Dude::GLOBAL_DIR, name)
        data = target && @home.read_dude_data(target)
        data && ::Dude::Dudes::Dude.new(data.merge(name: name, registry: self))
      end
    end
  end
end

require_relative './home'
require_relative './tasks'
require_relative './inbox'
require_relative './dude'
