require_relative 'format'
require_relative 'daily_checkpoint'
require_relative 'rate_limit'

module Dude
  module StatusLine
    class EnterpriseSpend
      include Dude::StatusLine::Format
      MONTHLY_BUDGET = 175.0

      attr_reader :daily_bar, :monthly_bar

      def initialize(month_spend, today_spend, time_provider = nil, date_provider = nil, checkpoint = nil)
        @month_spend = month_spend
        @today_spend = today_spend
        @time_provider = time_provider || method(:default_time)
        @date_provider = date_provider || method(:default_date)
        @checkpoint = checkpoint
      end

      def daily_bar
        daily_budget = calculate_daily_budget
        return nil if daily_budget.nil? || daily_budget <= 0

        used_pct = (@today_spend / daily_budget) * 100

        midnight_tonight = next_midnight
        window_len = 86400

        Dude::StatusLine::RateLimit.new(
          used_pct: used_pct,
          resets_at: midnight_tonight,
          window_len: window_len,
          emoji: '☀️'
        ).to_s
      end

      def monthly_bar
        used_pct = (@month_spend / MONTHLY_BUDGET) * 100

        first_of_next_month = first_of_next_month_ts
        window_len = seconds_in_current_month

        Dude::StatusLine::RateLimit.new(
          used_pct: used_pct,
          resets_at: first_of_next_month,
          window_len: window_len,
          emoji: '🌙'
        ).to_s
      end

      private

      def default_time
        Time.now
      end

      def default_date
        Date.today
      end

      def calculate_daily_budget
        checkpoint = @checkpoint || Dude::StatusLine::DailyCheckpoint.new
        checkpoint_data = checkpoint.read

        current_date = @date_provider.call.to_s
        checkpoint_date = checkpoint_data[:date]

        month_spend_at_start = checkpoint_data[:month_spend_at_day_start]
        days_left = checkpoint_data[:days_left]

        if checkpoint_date == current_date && month_spend_at_start && days_left
          (MONTHLY_BUDGET - month_spend_at_start) / days_left.to_f
        else
          nil
        end
      end

      def next_midnight
        now = @time_provider.call
        midnight = Time.new(now.year, now.month, now.day, 0, 0, 0)
        (midnight + 86400).to_i
      end

      def first_of_next_month_ts
        now = @time_provider.call
        if now.month == 12
          Time.new(now.year + 1, 1, 1, 0, 0, 0).to_i
        else
          Time.new(now.year, now.month + 1, 1, 0, 0, 0).to_i
        end
      end

      def seconds_in_current_month
        now = @time_provider.call
        if now.month == 12
          end_of_month = Time.new(now.year + 1, 1, 1, 0, 0, 0)
        else
          end_of_month = Time.new(now.year, now.month + 1, 1, 0, 0, 0)
        end
        start_of_month = Time.new(now.year, now.month, 1, 0, 0, 0)
        (end_of_month - start_of_month).to_i
      end
    end
  end
end
