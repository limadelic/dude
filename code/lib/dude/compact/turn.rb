require 'time'

module Dude
  module Compact
    class Turn
      NOISE_TAGS = %w[
        <cross-session-message
        <user-prompt-submit-hook
        <hook
        <system-reminder
        <task-notification
      ]
      INTERRUPT = '[Request interrupted by user]'
      IMAGE_TAG = /\s*\[Image #\d+\]/

      def initialize(entry)
        @entry = entry
      end

      def ask?
        return false unless user? && !meta? && typed?

        !noise?(text)
      end

      def text
        plain_text&.gsub(IMAGE_TAG, '')&.strip
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
        content.select { |b| b['type'] == 'text' && !noise?(b['text']) }
      end

      def noise?(text)
        NOISE_TAGS.any? { |tag| text.start_with?(tag) }
      end
    end
  end
end
