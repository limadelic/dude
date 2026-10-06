require 'json'

module Dude
  module Transcript
    class CacheStalenessChecker
      def initialize(cache_path)
        @cache_path = cache_path
      end

      def stale?
        return true unless File.exist?(@cache_path)
        return true if any_file_changed?

        false
      rescue JSON::ParserError, StandardError
        true
      end

      private

      def any_file_changed?
        cache_data = JSON.load_file(@cache_path)
        return false unless cache_data && cache_data['files']

        cache_data['files'].any? do |file_path, (mtime, offset)|
          file_changed?(file_path, mtime, offset)
        end
      end

      def file_changed?(file_path, cached_mtime, cached_offset)
        stat = File.stat(file_path)
        stat.mtime.to_i != cached_mtime || stat.size > cached_offset
      rescue Errno::ENOENT
        false
      end
    end
  end
end
