require_relative 'format'

module Dude
  module StatusLine
    class Spend
      include Dude::StatusLine::Format

      SPEND_CAP = ENV.fetch('CLAUDE_SPEND_CAP', '50').to_i

      def initialize(activity_data)
        @activity_data = activity_data
      end

      def to_s
        pct, min = spend_pct
        blocks = [(pct * 9 / 100.0).round, min].max
        bars = "#{'█' * blocks}#{'░' * (9 - blocks)}"
        "#{color_for_pct(pct)}💰 #{bars}#{COLORS[:reset]}"
      end

      private

      def spend_pct
        spend = @activity_data.dig('results', 0, 'metrics', 'spend')&.to_f || 0
        [clamp((spend / SPEND_CAP * 100).round), spend > 0 ? 1 : 0]
      end
    end
  end
end
