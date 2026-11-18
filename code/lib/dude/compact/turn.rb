require 'time'

module Dude
  module Compact
    class Turn
      NOISE_PREFIXES = [
        '<cross-session-message',
        '<user-prompt-submit-hook',
        '<hook',
        '<system-reminder',
        '<task-notification',
        '<scheduled-task',
        'heartbeat:',
        'Base directory for this skill:'
      ]
      INTERRUPT = '[Request interrupted by user]'
      IMAGE_TAG = /\s*\[Image #\d+\]/
      PASTE = %r{<pasted_content[^>]*>.*?</pasted_content>}m
      PASTE_MARK = '[paste]'
      COMMAND_NAME = %r{<command-name>(.*?)</command-name>}m
      COMMAND_ARGS = %r{<command-args>(.*?)</command-args>}m

      def initialize(entry)
        @entry = entry
      end

      def ask?
        return false unless user? && !meta? && typed?

        !noise?(text)
      end

      def text
        return command if command?

        plain_text&.gsub(PASTE, PASTE_MARK)&.gsub(IMAGE_TAG, '')&.strip
      end

      def time
        Time.parse(@entry['timestamp'])
      end

      private

      def user?
        @entry['type'] == 'user'
      end

      def meta?
        @entry['isMeta'] || @entry['isCompactSummary']
      end

      def typed?
        !text.to_s.empty? && text != INTERRUPT
      end

      def command?
        plain_text&.include?('<command-name>')
      end

      def command
        name = plain_text[COMMAND_NAME, 1]
        args = plain_text[COMMAND_ARGS, 1]
        [name, args].join(' ').strip
      end

      def plain_text
        content = @entry.dig('message', 'content')
        return content if content.is_a?(String)
        return unless content.is_a?(Array) && no_tool_result?(content)

        text_blocks(content).map { |b| b['text'] }.join("\n")
      end

      def no_tool_result?(blocks)
        blocks.none? { |b| b['type'] == 'tool_result' }
      end

      def text_blocks(content)
        content.select do |b|
          b['type'] == 'text' && b['text'] && !noise?(b['text'])
        end
      end

      def noise?(text)
        NOISE_PREFIXES.any? { |prefix| text.start_with?(prefix) }
      end
    end
  end
end
