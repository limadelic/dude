module Dude
  module Transcript
    class SessionIdExtractor
      def call(path)
        if path.include?('/subagents/')
          extract_parent_session_id(path)
        else
          extract_direct_session_id(path)
        end
      end

      private

      def extract_parent_session_id(path)
        parts = path.split('/')
        subagents_index = parts.index('subagents')
        return nil unless subagents_index && subagents_index > 0

        parts[subagents_index - 1]
      end

      def extract_direct_session_id(path)
        File.basename(path, '.jsonl')
      end
    end
  end
end
