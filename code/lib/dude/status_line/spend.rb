require_relative 'format'
require_relative 'daily_checkpoint'

module Dude
  module StatusLine
    class Spend
      include Dude::StatusLine::Format

      def initialize(token_fetcher, client = nil)
        @token_fetcher = token_fetcher
        @client = client
      end

      def to_s
        bootstrap_checkpoint
        handle_day_rollover

        token = @token_fetcher.fetch
        return empty_bar if token.empty?

        pct = calculate_daily_target_pct
        pct = clamp(pct)
        build_bar(pct)
      end

      private

      def bootstrap_checkpoint
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        if checkpoint.read.empty?
          checkpoint.write(month_total: 0, date: Date.today.to_s)
        end
      end

      def handle_day_rollover
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        data = checkpoint.read
        checkpoint_date = data[:daily_checkpoint_date]
        today = Date.today.to_s

        if checkpoint_date && checkpoint_date != today
          monthly_spend = @client ? @client.fetch : 0
          checkpoint.write(month_total: monthly_spend, date: today)
        end
      rescue StandardError
      end

      def calculate_daily_target_pct
        monthly_spend = @client ? @client.fetch : 0
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        checkpoint_data = checkpoint.read
        checkpoint_month_total = checkpoint_data[:daily_checkpoint_month_total] || 0

        today_actual = monthly_spend - checkpoint_month_total
        remaining_budget = 175.0 - monthly_spend
        remaining_days = days_left_in_month

        if remaining_days <= 0 || remaining_budget <= 0
          return 100.0
        end

        today_target = remaining_budget / remaining_days
        if today_target <= 0
          return 100.0
        end

        (today_actual / today_target * 100).round
      rescue StandardError
        0
      end

      def days_left_in_month
        today = Date.today
        last_day = Date.new(today.year, today.month, -1)
        (last_day - today).to_i + 1
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
