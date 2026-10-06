require 'json'
require_relative '../helpers/json'
require_relative 'format'
require_relative '../pomo/pomo'
require_relative '../dudes/dudes'
require_relative 'context'
require_relative 'context_percentage'
require_relative 'models'
require_relative 'dudes'
require_relative 'rate_limit'
require_relative 'enterprise_spend_provider'
require_relative 'price_table'
require_relative 'sun_band'
require_relative 'week_band'
require_relative 'silo_list'
require_relative '../transcript/silo_usage'
require_relative '../transcript/silo_registry'
require_relative '../transcript/usage_cache_store'

module Dude
  module StatusLine
    class SiloListBuilder
      def initialize(session)
        @session = session
      end

      def build_usage
        cache_store = load_cache_store
        registry = build_registry
        Dude::Transcript::SiloUsage.new(
          cache_store, build_sessions_to_silos(registry), '5h'
        )
      rescue StandardError
        nil
      end

      def build_registry
        Dude::Transcript::SiloRegistry.new.tap(&:load)
      rescue StandardError
        nil
      end

      private

      def build_sessions_to_silos(registry)
        return {} unless registry

        map_sessions_to_silos(registry, extract_session_ids)
      rescue StandardError
        {}
      end

      def map_sessions_to_silos(registry, session_ids)
        roster = registry.roster
        session_ids.each_with_object({}) do |session_id, map|
          silo_id = find_silo_for_session(session_id, roster)
          map[session_id] = silo_id if silo_id
        end
      end

      def find_silo_for_session(session_id, roster)
        roster.each_value do |silo_data|
          return silo_data['id'] if silo_data['id'] == session_id
        end
        nil
      end

      def extract_session_ids
        windows = load_cache_store&.instance_variable_get(:@windows)
        return [] unless windows

        windows.each_value.flat_map { |w| w[:costs]&.keys }.compact.uniq
      rescue StandardError
        []
      end

      def load_cache_store
        Dude::Transcript::UsageCacheStore.new.load(
          Dude::StatusLine::PriceTable.new
        )
      end
    end

    class Runner
      include Dude::StatusLine::Format

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

      def context_percentage
        @context_percentage ||= Dude::StatusLine::ContextPercentage.new(@session).value
      end

      def build_status_line(dudes_instance)
        sections = SectionBuilder.new(
          @session, @activity,
          context_percentage
        ).build
        [*sections.compact, dudes_instance.to_s].compact.join(' ')
      end

      def load_dudes
        Dude::Dudes::Dudes.new.all
      end
    end

    class SectionBuilder
      def initialize(session, activity, context_pct)
        @session = session
        @activity = activity
        @context_pct = context_pct
      end

      def build
        if @session['rate_limits']
          rate_limit_sections
        else
          enterprise_sections
        end
      end

      private

      def rate_limit_sections
        [
          context_section, pomo_section, five_hour_section, silo_list_section,
          seven_day_section, models_section
        ]
      end

      def enterprise_sections
        [
          context_section, pomo_section,
          enterprise_daily_section, enterprise_monthly_section, models_section
        ]
      end

      def context_section
        Dude::StatusLine::Context.new(@session, @context_pct).to_s
      end

      def pomo_section
        Dude::Pomo::Pomo.new.to_s
      end

      def models_section
        Dude::StatusLine::Models.new(@session, activity_data).to_s
      end

      def activity_data
        @activity_data ||= @activity || {}
      end

      def five_hour_section
        return unless @session['rate_limits']&.dig('five_hour')

        Dude::StatusLine::RateLimit.new(
          used_pct: @session.dig(
            'rate_limits', 'five_hour',
            'used_percentage'
          ) || 0,
          resets_at: @session.dig('rate_limits', 'five_hour', 'resets_at') || 0,
          window_len: 5 * 3600,
          emoji: '☀️',
          band: five_hour_band
        ).to_s
      end

      def silo_list_section
        return unless @session['rate_limits']&.dig('five_hour')

        render_silo_list
      rescue StandardError
        nil
      end

      def render_silo_list
        builder = SiloListBuilder.new(@session)
        build_and_render_list(builder)
      end

      def build_and_render_list(builder)
        silo_usage = builder.build_usage
        registry = builder.build_registry
        return unless silo_usage && registry

        result = Dude::StatusLine::SiloList.new(silo_usage, registry).call
        result.empty? ? nil : result
      end

      def seven_day_section
        return unless @session['rate_limits']&.dig('seven_day')

        Dude::StatusLine::RateLimit.new(
          used_pct: @session.dig(
            'rate_limits', 'seven_day',
            'used_percentage'
          ) || 0,
          resets_at: @session.dig('rate_limits', 'seven_day', 'resets_at') || 0,
          window_len: 7 * 24 * 3600,
          emoji: '🌙',
          band: seven_day_band
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

      def token
        @memoized_token ||= Dude::StatusLine::AnthropicToken.fetch
      end

      def five_hour_band
        @five_hour_band ||= Dude::StatusLine::SunBand.new(@session).call
      end

      def seven_day_band
        @seven_day_band ||= Dude::StatusLine::WeekBand.new(@session).call
      end
    end
  end
end
