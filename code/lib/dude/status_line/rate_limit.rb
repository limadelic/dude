require_relative 'format'

module Dude
  module StatusLine
    class RateLimit
      include Dude::StatusLine::Format
      COLORS = Dude::StatusLine::Format::COLORS

      def initialize(used_pct:, resets_at:, window_len:, emoji:)
        @used_pct = used_pct
        @resets_at = resets_at
        @window_len = window_len
        @emoji = emoji
      end

      def to_s
        elapsed = @window_len - (@resets_at - Time.now.to_i)
        elapsed_pct = clamp(elapsed * 100 / @window_len.to_f)
        ratio = elapsed_pct <= 0 ? 0 : @used_pct / elapsed_pct.to_f
        color = color_for_ratio(ratio)
        bar(clamp(@used_pct), @emoji, color: color)
      end

      private

      def color_for_ratio(ratio)
        case ratio
        when 0..1.0 then COLORS[:green]
        when 1.0..2.0 then COLORS[:yellow]
        else COLORS[:red]
        end
      end
    end
  end
end
