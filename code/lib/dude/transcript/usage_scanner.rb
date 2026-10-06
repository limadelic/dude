require_relative 'usage_cache'
require_relative 'transcript_usage'
require_relative 'session_id_extractor'

module Dude
  module Transcript
    class UsageScanner
      def scan(cache, paths, windows)
        @usage = TranscriptUsage.new
        @extractor = SessionIdExtractor.new
        @windows = windows
        @cache = cache

        paths.each { |path| scan_file(path) }
      end

      private

      def scan_file(path)
        stat = File.stat(path)
        return if should_skip?(path, stat)

        offset = resume_offset(@cache.file_state(path), stat.size)
        process(path, read_file_from(path, offset), offset, stat.mtime)
      end

      def should_skip?(path, stat)
        cached = @cache.file_state(path)
        cached && cached[0] == stat.mtime
      end

      def process(path, content, start_offset, mtime)
        last_newline = content.rindex("\n")
        return if last_newline.nil?

        process_lines(path, content, start_offset, mtime, last_newline)
      end

      def process_lines(path, content, start_offset, mtime, last_newline)
        lines = content[0..last_newline].split("\n").reject(&:empty?)
        session = @extractor.call(path)
        lines.each { |line| process_line(line, session) }
        @cache.set_file_state(path, mtime, start_offset + last_newline + 1)
      end

      def process_line(line, session)
        record = @usage.parse(line)
        return unless record

        record[:session] = session
        @windows.each { |w| @cache.add(w, record) }
      end

      def resume_offset(cached_state, current_size)
        return 0 unless cached_state && current_size >= cached_state[1]

        cached_state[1]
      end

      def read_file_from(path, offset)
        f = File.open(path, 'r')
        f.read(offset) if offset > 0
        content = f.read
        f.close
        content
      end
    end
  end
end
