require 'json'
require 'fileutils'
require_relative 'pub_finder'
require_relative 'process_manager'

module Dude
  module Dudes
    class Pub
      def self.find_nearest_pub(start_path)
        ::Dude::Dudes::PubFinder.find_nearest_pub(start_path)
      end

      def initialize(target:)
        @target = target
      end

      def pub(target, name)
        given_name = name
        name ||= File.basename(target)
        dir = claude_dir(target)
        register(dir, name, File.join(dir, 'dudes'), ::Dude::GLOBAL_DIR)
        given_name || target
      end

      def unpub(target)
        return unless Dir.exist?(::Dude::GLOBAL_DIR)

        remove_dudes
        ::Dude::Dudes::ProcessManager.kill_watchers
      end

      def sub(target, name)
        name ||= File.basename(target)
        parent_pub = ::Dude::Dudes::PubFinder.find_nearest_pub(target)
        full_name = "#{parent_pub[:name]}_#{name}"
        dudes_path = File.join(parent_pub[:path], 'dudes')
        register(claude_dir(target), full_name, dudes_path, dudes_path)
      end

      private

      def register(dir, name, dudes_dir, dest_dir)
        FileUtils.mkdir_p(dudes_dir)
        init_inbox(dudes_dir)
        write_status(dudes_dir, name)
        create_symlink(dir, name, dest_dir)
        name
      end

      def claude_dir(cwd)
        return cwd if File.basename(cwd) == '.claude'

        c = File.join(cwd, '.claude')
        Dir.exist?(c) ? c : cwd
      end

      def init_inbox(dudes_dir)
        path = File.join(dudes_dir, 'inbox.json')
        File.write(path, '[]') unless File.exist?(path)
      end

      def write_status(dudes_dir, name)
        path = File.join(dudes_dir, 'status.json')
        existing = load_existing(path)
        File.write(path, existing.merge('name' => name).to_json)
      end

      def load_existing(path)
        return {} unless File.exist?(path)

        JSON.load_file(path) rescue {}
      end

      def create_symlink(dir, name, dest_dir)
        FileUtils.mkdir_p(dest_dir) if dest_dir == ::Dude::GLOBAL_DIR
        link = File.join(dest_dir, name)
        File.delete(link) if File.symlink?(link)
        File.symlink("#{dir}/", link)
      end

      def remove_dudes
        Dir.children(::Dude::GLOBAL_DIR).each { |name| remove_dude(name) }
      end

      def remove_dude(name)
        path = File.join(::Dude::GLOBAL_DIR, name)
        return unless File.symlink?(path)

        target = File.readlink(path).chomp('/')
        FileUtils.rm_rf(File.join(target, 'dudes'))
        File.delete(path)
      end
    end
  end
end
