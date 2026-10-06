require 'json'
require 'fileutils'

module Dude
  module Transcript
    class UsageCacheStore
      def initialize(path = nil)
        @path = path || File.expand_path('~/.claude/dude/usage_cache.json')
      end

      def load(price_table)
        cache = UsageCache.new(price_table)
        cache.from_h(JSON.load_file(@path)) if File.exist?(@path)
        cache
      rescue JSON::ParserError, StandardError
        UsageCache.new(price_table)
      end

      def save(cache)
        data = cache.to_h
        temp_path = @path + ".tmp.#{$$}"

        FileUtils.mkdir_p(File.dirname(@path))
        File.write(temp_path, JSON.generate(data))
        File.rename(temp_path, @path)
      end
    end
  end
end
