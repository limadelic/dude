require_relative 'format'

module Dude
  module StatusLine
    class Spend
      include Dude::StatusLine::Format

      DAILY_BUDGET = 8.75

      def initialize(token_fetcher, client = nil)
        @token_fetcher = token_fetcher
        @client = client
      end

      def to_s
        token = @token_fetcher.fetch
        return empty_bar if token.empty?

        daily_rate = fetch_daily_rate
        pct = clamp((daily_rate / DAILY_BUDGET * 100).round)
        build_bar(pct)
      end

      private

      def fetch_daily_rate
        monthly_spend = @client ? @client.fetch : 0
        day_of_month = Time.now.day
        monthly_spend / day_of_month
      rescue StandardError
        0
      end

      def build_bar(pct)
        blocks = [(pct * 9 / 100.0).round, pct > 0 ? 1 : 0].max
        bars = "#{'█' * blocks}#{'░' * (9 - blocks)}"
        "#{color_for_pct(pct)}💰 #{bars}#{COLORS[:reset]}"
      end

      def empty_bar
        "#{color_for_pct(0)}💰 #{'░' * 9}#{COLORS[:reset]}"
      end
    end
  end
end
