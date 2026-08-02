require_relative 'format'

module Dude
  module StatusLine
    class ContextPercentage
      include Dude::StatusLine::Format

      AUTOCOMPACT_WINDOW = 200_000

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
        tokens * 100 / AUTOCOMPACT_WINDOW.to_f
      end

      private

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
