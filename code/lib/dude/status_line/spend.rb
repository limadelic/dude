require 'time'
require_relative 'format'
require_relative 'daily_checkpoint'

module Dude
  module StatusLine
    class Spend
      include Dude::StatusLine::Format

      def initialize(token_fetcher, client = nil, clock = nil)
        @token_fetcher = token_fetcher
        @client = client
        @clock = clock || Time
      end

      def to_s
        bootstrap_checkpoint
        handle_day_rollover
        token = @token_fetcher.fetch
        return empty_bar if token.empty?

        build_bar(calculate_rate_per_min)
      end

      private

      def bootstrap_checkpoint
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        if checkpoint.read.empty?
          today = now.to_date.to_s
          checkpoint.write(spent: 0, date: today)
        end
      end

      def handle_day_rollover
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        today = now.to_date.to_s
        write_new_checkpoint(checkpoint, today) if
          !checkpoint.read[:date] || checkpoint.read[:date] != today
      rescue StandardError
      end

      def days_remaining_in_month
        today = now.to_date
        last_day = Date.new(today.year, today.month, -1)
        (last_day - today).to_i + 1
      end

      def calculate_rate_per_min
        mins = minutes_elapsed_today
        return 0 if mins < 1

        spend_cap_pct || burn_rate_pct(mins)
      rescue
        0
      end

      def spend_cap_pct
        spend_cap = ENV['CLAUDE_SPEND_CAP'].to_i if ENV['CLAUDE_SPEND_CAP']
        (current_day_spend / spend_cap.to_f) * 100 if spend_cap && spend_cap > 0
      end

      def burn_rate_pct(mins)
        clamp_rate(calculate_pct(mins))
      end

      def build_bar(pct)
        blocks = [(pct * 9 / 100.0).round, pct > 0 ? 1 : 0].max
        blocks = [blocks, 9].min
        bars = "#{'█' * blocks}#{'░' * (9 - blocks)}"
        # Use different thresholds when using spend cap vs burn rate
        thresholds = ENV['CLAUDE_SPEND_CAP'] ? [33, 66] : [100, 300]
        "#{color_for_pct(pct, *thresholds)}💰 #{bars}#{COLORS[:reset]}"
      end

      def empty_bar
        "#{color_for_pct(0)}💰 #{'░' * 9}#{COLORS[:reset]}"
      end

      def write_new_checkpoint(checkpoint, today)
        monthly_spend = @client ? @client.fetch : 0
        days_left = days_remaining_in_month
        checkpoint.write(
          spent: monthly_spend,
          date: today,
          month_spend_at_day_start: monthly_spend,
          days_left: days_left
        )
      end

      def current_day_spend
        monthly_spend = @client ? @client.fetch : 0
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        checkpoint_spent = checkpoint.read[:spent] || 0
        monthly_spend - checkpoint_spent
      end

      def minutes_elapsed_today
        ct = now
        midnight = Time.new(ct.year, ct.month, ct.day, 0, 0, 0)
        ((ct - midnight) / 60).to_i
      end

      def now
        @clock.now
      end

      def calculate_pct(mins)
        baseline = 175.0 / 1440.0
        (current_day_spend / mins.to_f / baseline) * 100
      end

      def clamp_rate(pct)
        [[pct, 0].max, 300].min
      end
    end
  end
end
