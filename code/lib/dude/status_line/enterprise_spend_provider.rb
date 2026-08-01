require_relative 'anthropic_token'
require_relative 'anthropic_spend_client'
require_relative 'spend_cache'
require_relative 'enterprise_spend'
require_relative 'daily_checkpoint'

module Dude
  module StatusLine
    class EnterpriseSpendProvider
      def initialize(session, token = nil)
        @session = session
        @token = token
      end

      def get
        return @spend if defined?(@spend)

        @spend = build_spend_object
      end

      private

      def build_spend_object
        token = token_value
        return nil if token.nil? || token.empty?

        prepare_and_return_spend(token)
      rescue StandardError
        nil
      end

      def prepare_and_return_spend(token)
        month_spend = fetch_month_spend(token)
        ensure_daily_checkpoint_valid(month_spend)
        today_spend = calculate_today_spend(month_spend)
        Dude::StatusLine::EnterpriseSpend.new(month_spend, today_spend)
      end

      def token_value
        @token || Dude::StatusLine::AnthropicToken.fetch
      end

      def fetch_month_spend(token)
        Dude::StatusLine::SpendCache.new.fetch do
          c = Dude::StatusLine::AnthropicSpendClient
          u = ENV['CLAUDE_ACTIVITY_URL']
          (u ? c.new(token, nil, u) : c.new(token)).fetch
        end
      end

      def ensure_daily_checkpoint_valid(month_spend)
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        data = checkpoint.read
        today = Date.today.to_s
        update_checkpoint(checkpoint, month_spend, data, today)
      rescue StandardError
      end

      def update_checkpoint(checkpoint, month_spend, data, today)
        return unless checkpoint_needs_update?(data, today)

        write_checkpoint_for_today(checkpoint, month_spend, today)
      end

      def write_checkpoint_for_today(checkpoint, month_spend, today)
        last_day = Date.new(Date.today.year, Date.today.month, -1)
        days_left = (last_day - Date.today).to_i + 1
        checkpoint.write(
          spent: month_spend,
          date: today,
          month_spend_at_day_start: month_spend,
          days_left: days_left
        )
      end

      def checkpoint_needs_update?(data, today)
        data[:date].nil? || data[:date] != today ||
          data[:month_spend_at_day_start].nil? || data[:days_left].nil?
      end

      def calculate_today_spend(month_spend)
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        checkpoint_spent = checkpoint.read[:spent] || 0
        month_spend - checkpoint_spent
      end
    end
  end
end
