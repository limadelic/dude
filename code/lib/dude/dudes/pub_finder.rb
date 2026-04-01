module Dude
  module Dudes
    class PubFinder
      def self.find_nearest_pub(start_path)
        find_pub_walking_up(start_path) || global_pub
      end

      def self.find_pub_walking_up(start_path)
        return nil unless File.exist?(start_path.chomp('/'))

        walk_up_from(start_path.chomp('/'))
      end

      def self.find_pub_name_for_target(target)
        registry.find_name_for_target(target)
      end

      private

      def self.walk_up_from(current)
        check_for_pub_in(current) || (parent = parent_dir(current)) &&
          walk_up_from(parent)
      end

      def self.check_for_pub_in(dir)
        claude_dir = File.join(dir, '.claude')
        return nil unless Dir.exist?(claude_dir)

        pub_name = find_pub_name_for_target(claude_dir)
        pub_name ? {
          name: pub_name,
          path: File.join(claude_dir, 'dudes')
        } : nil
      end

      def self.parent_dir(current)
        parent = File.dirname(current)
        parent == current ? nil : parent
      end

      def self.registry
        @registry ||= SymlinkRegistry.new
      end

      def self.global_pub
        { name: 'global', path: ::Dude::GLOBAL_DIR }
      end

      class SymlinkRegistry
        def find_name_for_target(target)
          return nil unless Dir.exist?(::Dude::GLOBAL_DIR)

          Dir.children(::Dude::GLOBAL_DIR).find { |n| matches?(n, target) }
        end

        private

        def matches?(name, target)
          link = File.join(::Dude::GLOBAL_DIR, name)
          return false unless File.symlink?(link)

          File.readlink(link).chomp('/') == target.chomp('/')
        end
      end
    end
  end
end
