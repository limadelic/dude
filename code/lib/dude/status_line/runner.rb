require 'json'
require_relative '../helpers/json'
require_relative 'format'
require_relative '../pomo/pomo'
require_relative '../dudes/dudes'
require_relative 'context'
require_relative 'context_percentage'
require_relative 'spend'
require_relative 'models'
require_relative 'dudes'
require_relative 'rate_limit'
require_relative 'enterprise_spend_provider'
require_relative 'spend_section'

module Dude
  module StatusLine
    class Runner
      include Dude::StatusLine::Format
      include Dude::StatusLine::SpendSection

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
        r = @session['rate_limits'] ? rate_limit_sections : enterprise_sections
        r.compact.join(' ')
      end

      def rate_limit_sections
        [
          context_section, spend_section(token), pomo_section,
          five_hour_section, seven_day_section, models_section
        ]
      end

      def enterprise_sections
        [
          context_section, spend_section(token), pomo_section,
          enterprise_daily_section, enterprise_monthly_section, models_section
        ]
      end

      def token
        @memoized_token ||= Dude::StatusLine::AnthropicToken.fetch
      end

      def context_section
        Dude::StatusLine::Context.new(@session, context_percentage).to_s
      end

      def context_percentage
        @context_percentage ||= Dude::StatusLine::ContextPercentage.new(@session).value
      end

      def load_dudes
        Dude::Dudes::Dudes.new.all
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
          used_pct: @session.dig(
            'rate_limits', 'five_hour',
            'used_percentage'
          ) || 0,
          resets_at: @session.dig('rate_limits', 'five_hour', 'resets_at') || 0,
          window_len: 5 * 3600,
          emoji: '☀️'
        ).to_s
      end

      def seven_day_section
        return unless @session['rate_limits']

        Dude::StatusLine::RateLimit.new(
          used_pct: @session.dig(
            'rate_limits', 'seven_day',
            'used_percentage'
          ) || 0,
          resets_at: @session.dig('rate_limits', 'seven_day', 'resets_at') || 0,
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
        @enterprise_spend ||= Dude::StatusLine::EnterpriseSpendProvider.new(
          @session, token
        ).get
      end
    end
  end
end
