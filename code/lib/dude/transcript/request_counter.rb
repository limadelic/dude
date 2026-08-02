require 'json'
require_relative '../model_families'

module Dude
  module Transcript
    class RequestCounter
      def count(path)
        return {} unless File.exist?(path)

        perform_count(path)
      rescue SystemCallError
        {}
      end

      def perform_count(path)
        counts = {}
        process_transcript_file(path, counts)
        process_subagent_files(path, counts)
        counts
      end

      private

      def process_transcript_file(path, counts)
        seen_ids = Set.new
        File.read(path).each_line do |line|
          parse_and_count(line, counts, seen_ids)
        end
      end

      def process_subagent_files(path, counts)
        subagent_dir = subagent_directory(path)
        return unless subagent_dir && Dir.exist?(subagent_dir)

        process_agent_files(subagent_dir, counts)
      rescue SystemCallError
        nil
      end

      def subagent_directory(path)
        session_id = File.basename(path, '.jsonl')
        File.join(File.dirname(path), session_id, 'subagents')
      end

      def process_agent_files(subagent_dir, counts)
        Dir.glob("#{subagent_dir}/agent-*.jsonl").each do |agent_file|
          process_agent_file(agent_file, counts)
        end
      end

      def process_agent_file(agent_file, counts)
        seen_ids = Set.new
        File.read(agent_file).each_line do |line|
          parse_and_count(line, counts, seen_ids)
        end
      end

      def parse_and_count(line, counts, seen_ids)
        parsed = parse_line(line)
        return unless parsed && valid_message?(parsed['message'], seen_ids)

        family = extract_family_from_message(parsed['message'])
        increment_count(parsed['message'], family, counts, seen_ids) if family
      end

      def valid_message?(message, seen_ids)
        model = message&.dig('model')
        id = message&.dig('id')
        model && id && !seen_ids.include?(id)
      end

      def extract_family_from_message(message)
        model = message&.dig('model')
        extract_family(model) if model
      end

      def increment_count(message, family, counts, seen_ids)
        id = message['id']
        seen_ids.add(id)
        counts[family] = (counts[family] || 0) + 1
      end

      def parse_line(line)
        JSON.parse(line.strip)
      rescue JSON::ParserError
        nil
      end

      def extract_family(model)
        families = Dude::ModelFamilies::ALL.map(&:first)
        families.find { |family| model.include?(family) }
      end
    end
  end
end
