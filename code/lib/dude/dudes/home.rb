require_relative '../helpers/json'
require_relative './inbox'
require_relative './path_resolver'

module Dude
  module Dudes
    class Home
      include ::Dude::Helpers::Json

      def list_dude_names(dir)
        Dir.children(dir).select { |n| File.symlink?(File.join(dir, n)) }
      rescue
        []
      end

      def read_dude_link(dudes_dir, name)
        link_path = File.join(dudes_dir, name)
        return nil unless File.symlink?(link_path)

        link_target = File.readlink(link_path)
        target = path_resolver.expand_target(link_target, dudes_dir)
        is_accessible?(target) ? target : nil
      end

      def read_dude_data(target)
        icon = read_icon(File.join(target, 'CLAUDE.md'))
        return nil unless icon

        compose_dude_data(icon, target)
      end

      private

      def compose_dude_data(icon, target)
        dude_dir = File.join(target, 'dudes')
        inbox_file = File.join(dude_dir, 'inbox.json')
        {
          icon: icon, target: target, status: read_status(dude_dir),
          inbox: ::Dude::Dudes::Inbox.new(inbox_file), dude_dir: dude_dir
        }
      end

      def read_status(dude_dir)
        read_json(File.join(dude_dir, 'status.json')) || {}
      end

      def path_resolver
        @path_resolver ||= ::Dude::Dudes::PathResolver.new
      end

      def is_accessible?(target)
        ::Dude::Dudes::Dudes.pids.any? { |_pid, cwd| cwd == target || File.dirname(target) == cwd }
      end
    end
  end
end
