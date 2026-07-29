require 'json'

module Dude
  module Transcript
    class RequestCounter
      def count(path)
        return {} unless File.exist?(path)

        counts = {}
        process_transcript_file(path, counts)
        process_subagent_files(path, counts)
        counts
      rescue SystemCallError
        {}
      end

      private

      def process_transcript_file(path, counts)
        seen_ids = Set.new
        File.read(path).each_line do |line|
          parse_and_count(line, counts, seen_ids)
        end
      end

      def process_subagent_files(path, counts)
        session_id = File.basename(path, '.jsonl')
        subagent_dir = File.join(File.dirname(path), session_id, 'subagents')

        return unless Dir.exist?(subagent_dir)

        Dir.glob("#{subagent_dir}/agent-*.jsonl").each do |agent_file|
          seen_ids = Set.new
          File.read(agent_file).each_line do |line|
            parse_and_count(line, counts, seen_ids)
          end
        end
      rescue SystemCallError
        nil
      end

      def parse_and_count(line, counts, seen_ids)
        parsed = parse_line(line)
        return unless parsed

        model = parsed['message']&.dig('model')
        id = parsed['message']&.dig('id')

        return unless model && id
        return if seen_ids.include?(id)

        family = extract_family(model)
        return unless family

        seen_ids.add(id)
        counts[family] = (counts[family] || 0) + 1
      end

      def parse_line(line)
        JSON.parse(line.strip)
      rescue JSON::ParserError
        nil
      end

      def extract_family(model)
        %w[opus haiku sonnet fable].find { |family| model.include?(family) }
      end
    end
  end
end
