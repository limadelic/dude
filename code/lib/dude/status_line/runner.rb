require 'json'
require_relative '../helpers/json'
require_relative 'format'
require_relative '../pomo/pomo'
require_relative '../dudes/dudes'
require_relative 'context'
require_relative 'spend'
require_relative 'models'
require_relative 'dudes'
require_relative 'anthropic_token'
require_relative 'anthropic_spend_client'
require_relative 'spend_cache'
require_relative 'rate_limit'
require_relative 'enterprise_spend'
require_relative 'daily_checkpoint'

module Dude
  module StatusLine
    class Runner
      include Dude::StatusLine::Format

      COLORS = Dude::StatusLine::Format::COLORS
      SUPERSCRIPTS = Dude::StatusLine::Format::SUPERSCRIPTS
      BG_MAP = Dude::StatusLine::Format::BG_MAP
      WHITE = Dude::StatusLine::Format::WHITE
      JETBRAINS = Dude::StatusLine::Format::JETBRAINS
      AUTOCOMPACT_WINDOW = 200_000

      def initialize(json_input, activity: nil, dudes: nil, cwd: Dir.pwd)
        @session = (JSON.parse(json_input) rescue default_session)
        @activity, @dudes, @cwd = activity, dudes, cwd
      end

      def run
        puts build_status_line(create_dudes_instance.tap(&:write_status))
      rescue StandardError => e
        handle_error(e)
      end

      private

      def default_session
        warn "Error parsing JSON: #{$!.message}"
        {}
      end

      def create_dudes_instance
        Dude::StatusLine::Dudes.new(
          @session, dudes_list, @cwd, context_percentage
        )
      end

      def dudes_list
        @dudes_list ||= @dudes || load_dudes
      end

      def handle_error(e)
        warn "Error: #{e.message}"
        puts "🧠 [ERROR: #{e.class}]"
      end

      def build_status_line(dudes_instance)
        if @session['rate_limits']
          sections = [
            context_section, five_hour_section, seven_day_section, models_section
          ]
        else
          sections = [
            context_section, enterprise_daily_section, enterprise_monthly_section, models_section
          ]
        end
        sections.compact.join(' ')
      end

      def context_section
        Dude::StatusLine::Context.new(@session, context_percentage).to_s
      end

      def context_percentage
        @context_percentage ||= begin
          cw = @session['context_window'] || {}
          tokens = cw['total_input_tokens'].to_i + cw['total_output_tokens'].to_i
          if tokens > 0
            pct = tokens * 100 / AUTOCOMPACT_WINDOW.to_f
          else
            pct = cw['used_percentage'] || 0
          end
          clamp(pct)
        end
      end

      def load_dudes
        Dude::Dudes::Dudes.new.all
      end

      def spend_section
        token_fetcher = Dude::StatusLine::AnthropicToken
        client = Dude::StatusLine::AnthropicSpendClient.new(token_fetcher.fetch)
        Dude::StatusLine::Spend.new(token_fetcher, client).to_s
      end

      def activity_data
        @activity_data ||= @activity || {}
      end

      def pomo_section
        Dude::Pomo::Pomo.new.to_s
      end

      def models_section
        Dude::StatusLine::Models.new(@session, activity_data).to_s
      end

      def five_hour_section
        return unless @session['rate_limits']
        Dude::StatusLine::RateLimit.new(
          used_pct: @session.dig('rate_limits','five_hour','used_percentage') || 0,
          resets_at: @session.dig('rate_limits','five_hour','resets_at') || 0,
          window_len: 5 * 3600,
          emoji: '☀️'
        ).to_s
      end

      def seven_day_section
        return unless @session['rate_limits']
        Dude::StatusLine::RateLimit.new(
          used_pct: @session.dig('rate_limits','seven_day','used_percentage') || 0,
          resets_at: @session.dig('rate_limits','seven_day','resets_at') || 0,
          window_len: 7 * 24 * 3600,
          emoji: '🌙'
        ).to_s
      end

      def enterprise_daily_section
        enterprise_spend&.daily_bar
      end

      def enterprise_monthly_section
        enterprise_spend&.monthly_bar
      end

      def enterprise_spend
        return @enterprise_spend if defined?(@enterprise_spend)

        @enterprise_spend = begin
          token = Dude::StatusLine::AnthropicToken.fetch
          if token.nil? || token.empty?
            nil
          else
            month_spend = Dude::StatusLine::SpendCache.new.fetch do
              Dude::StatusLine::AnthropicSpendClient.new(token).fetch
            end
            ensure_daily_lock(month_spend)
            checkpoint_spent = Dude::StatusLine::DailyCheckpoint.new.read[:spent] || 0
            today_spend = month_spend - checkpoint_spent
            Dude::StatusLine::EnterpriseSpend.new(month_spend, today_spend)
          end
        rescue StandardError
          nil
        end
      end

      def ensure_daily_lock(month_spend)
        checkpoint = Dude::StatusLine::DailyCheckpoint.new
        data = checkpoint.read
        today = Date.today.to_s

        if data[:date].nil? || data[:date] != today
          last_day = Date.new(Date.today.year, Date.today.month, -1)
          days_left = (last_day - Date.today).to_i + 1
          checkpoint.write(
            spent: month_spend,
            date: today,
            month_spend_at_day_start: month_spend,
            days_left: days_left
          )
        end
      rescue StandardError
      end
    end
  end
end
