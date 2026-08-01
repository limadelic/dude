require_relative 'format'
require_relative 'daily_checkpoint'
require_relative 'rate_limit'

module Dude
  module StatusLine
    class EnterpriseSpend
      include Dude::StatusLine::Format
      MONTHLY_BUDGET = 175.0

      def initialize(month_spend, today_spend, time_provider = nil,
        date_provider = nil, checkpoint = nil)
        @month_spend = month_spend
        @today_spend = today_spend
        @time_provider = time_provider || method(:default_time)
        @date_provider = date_provider || method(:default_date)
        @checkpoint = checkpoint
      end

      def daily_bar
        daily_budget = calculate_daily_budget
        return nil if invalid_budget?(daily_budget)

        rate_limit_for_day(daily_budget).to_s
      end

      def monthly_bar
        used_pct = (@month_spend / MONTHLY_BUDGET) * 100
        rate_limit_for_month(used_pct).to_s
      end

      private

      def invalid_budget?(budget)
        budget.nil? || !budget.finite? || budget <= 0
      end

      def rate_limit_for_day(budget)
        used_pct = (@today_spend / budget) * 100
        Dude::StatusLine::RateLimit.new(
          used_pct: used_pct,
          resets_at: next_midnight,
          window_len: 86400,
          emoji: '☀️'
        )
      end

      def rate_limit_for_month(used_pct)
        Dude::StatusLine::RateLimit.new(
          used_pct: used_pct,
          resets_at: first_of_next_month_ts,
          window_len: seconds_in_current_month,
          emoji: '🌙'
        )
      end

      def read_checkpoint
        checkpoint = @checkpoint || Dude::StatusLine::DailyCheckpoint.new
        checkpoint.read
      end

      def checkpoint_valid?(data)
        current_date = @date_provider.call.to_s
        data[:date] == current_date &&
          data[:month_spend_at_day_start] && data[:days_left] &&
          data[:days_left].to_i > 0
      end

      def default_time
        Time.now
      end

      def default_date
        Date.today
      end

      def calculate_daily_budget
        checkpoint_data = read_checkpoint
        return nil unless checkpoint_valid?(checkpoint_data)

        (MONTHLY_BUDGET - checkpoint_data[:month_spend_at_day_start]) /
          checkpoint_data[:days_left].to_f
      end

      def next_midnight
        now = @time_provider.call
        midnight = Time.new(now.year, now.month, now.day, 0, 0, 0)
        (midnight + 86400).to_i
      end

      def first_of_next_month_ts
        next_month_time = next_month_start
        next_month_time.to_i
      end

      def seconds_in_current_month
        end_of_month = next_month_start
        start_of_month = month_start
        (end_of_month - start_of_month).to_i
      end

      def next_month_start
        now = @time_provider.call
        month = now.month == 12 ? 1 : now.month + 1
        year = now.month == 12 ? now.year + 1 : now.year
        Time.new(year, month, 1, 0, 0, 0)
      end

      def month_start
        now = @time_provider.call
        Time.new(now.year, now.month, 1, 0, 0, 0)
      end
    end
  end
end
