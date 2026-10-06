require_relative 'format'

module Dude
  module StatusLine
    class ContextPercentage
      include Dude::StatusLine::Format

      DEFAULT_WINDOW = 200_000

      def initialize(session)
        @session = session
      end

      def value
        tokens = total_tokens
        pct = calculate_percentage(tokens)
        clamp(pct)
      end

      def calculate_percentage(tokens)
        tokens > 0 ? percentage_from_tokens(tokens) : fallback_percentage
      end

      def percentage_from_tokens(tokens)
        tokens * 100 / autocompact_window.to_f
      end

      private

      def autocompact_window
        env_window = ENV['CLAUDE_CODE_AUTO_COMPACT_WINDOW'].to_i
        cw = @session['context_window'] || {}
        session_window = cw['context_window_size'].to_i

        candidates = [env_window, session_window, DEFAULT_WINDOW]
          .select { |w| w > 0 }
        candidates.min
      end

      def total_tokens
        cw = @session['context_window'] || {}
        cw['total_input_tokens'].to_i + cw['total_output_tokens'].to_i
      end

      def fallback_percentage
        (@session.dig('context_window', 'used_percentage') || 0)
      end
    end
  end
end
