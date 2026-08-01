require 'json'
require 'time'

module Dude
  module StatusLine
    class SpendCache
      TTL_SECONDS = 300

      def initialize(cache_path = nil)
        default_path = '~/.claude/.spend-cache.json'
        @cache_path = cache_path || File.expand_path(default_path)
      end

      def fetch
        return read_cache if cache_fresh?

        spend = yield
        write_cache(spend)
        spend
      end

      private

      def cache_fresh?
        return false unless File.exist?(@cache_path)

        cache_age < TTL_SECONDS
      rescue StandardError
        false
      end

      def read_cache
        cached = JSON.parse(File.read(@cache_path))
        cached['spend']
      rescue StandardError
        nil
      end

      def write_cache(spend)
        cache_data = {
          'updated_at' => Time.now.iso8601,
          'spend' => spend
        }
        File.write(@cache_path, JSON.generate(cache_data))
      rescue StandardError
        nil
      end

      def cache_age
        cached = JSON.parse(File.read(@cache_path))
        updated_at = Time.iso8601(cached['updated_at'])
        Time.now - updated_at
      end
    end
  end
end
