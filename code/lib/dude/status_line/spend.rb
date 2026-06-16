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

        pct = calculate_rate_per_min
        build_bar(pct)
      end

      private

      def bootstrap_checkpoint
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        if checkpoint.read.empty?
          checkpoint.write(spent: 0, date: Date.today.to_s)
        end
      end

      def handle_day_rollover
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        data = checkpoint.read
        checkpoint_date = data[:date]
        today = Date.today.to_s

        if checkpoint_date && checkpoint_date != today
          monthly_spend = @client ? @client.fetch : 0
          days_left = days_remaining_in_month
          checkpoint.write(
            spent: monthly_spend,
            date: today,
            month_spend_at_day_start: monthly_spend,
            days_left: days_left
          )
        elsif !checkpoint_date
          monthly_spend = @client ? @client.fetch : 0
          days_left = days_remaining_in_month
          checkpoint.write(
            spent: monthly_spend,
            date: today,
            month_spend_at_day_start: monthly_spend,
            days_left: days_left
          )
        end
      rescue StandardError
      end

      def days_remaining_in_month
        today = Date.today
        last_day = Date.new(today.year, today.month, -1)
        (last_day - today).to_i + 1
      end

      def calculate_rate_per_min
        baseline_rate_per_min = 175.0 / 1440.0

        monthly_spend = @client ? @client.fetch : 0
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        checkpoint_data = checkpoint.read
        checkpoint_spent = checkpoint_data[:spent] || 0

        today_spend = monthly_spend - checkpoint_spent

        now = Time.now
        midnight = Time.new(now.year, now.month, now.day, 0, 0, 0)
        mins_since_midnight = ((now - midnight) / 60).to_i

        return 0 if mins_since_midnight < 1

        rate_per_min = today_spend / mins_since_midnight.to_f
        pct = (rate_per_min / baseline_rate_per_min) * 100
        [[pct, 0].max, 300].min
      rescue StandardError
        0
      end

      def build_bar(pct)
        blocks = [(pct * 9 / 100.0).round, pct > 0 ? 1 : 0].max
        blocks = [blocks, 9].min
        bars = "#{'█' * blocks}#{'░' * (9 - blocks)}"
        "#{color_for_pct(pct, 100, 300)}💰 #{bars}#{COLORS[:reset]}"
      end

      def empty_bar
        "#{color_for_pct(0)}💰 #{'░' * 9}#{COLORS[:reset]}"
      end
    end
  end
end
