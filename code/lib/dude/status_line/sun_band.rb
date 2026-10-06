require_relative '../transcript/usage_cache_store'
require_relative '../transcript/silo_registry'
require_relative '../transcript/current_silo'
require_relative '../transcript/silo_usage'
require_relative '../transcript/band'
require_relative 'price_table'

module Dude
  module StatusLine
    class SunBand
      def initialize(session_data)
        @session = session_data
      end

      # rubocop:disable Metrics/MethodLength
      def call
        return nil unless (silo_id = current_silo)
        return nil if (usage = silo_usage).active_count <= 1

        ratio = usage.ratio(silo_id)
        band_color(ratio, usage.active_count) if ratio
      rescue StandardError
        nil
      end
      # rubocop:enable Metrics/MethodLength

      private

      def current_silo
        @current_silo ||= Dude::Transcript::CurrentSilo.new(silo_registry).call(
          session_name: @session['session_name'],
          customTitle: @session['customTitle'],
          agentName: @session['agentName']
        )
      end

      def silo_registry
        @silo_registry ||= Dude::Transcript::SiloRegistry.new.tap(&:load)
      end

      def silo_usage
        @silo_usage ||= Dude::Transcript::SiloUsage.new(
          cache, sessions_to_silos, '5h'
        )
      end

      def cache
        @cache ||= Dude::Transcript::UsageCacheStore.new.load(price_table)
      end

      def price_table
        @price_table ||= Dude::StatusLine::PriceTable.new
      end

      def sessions_to_silos
        roster = silo_registry.roster

        session_ids.each_with_object({}) do |session_id, map|
          silo_id = find_silo_for_session(session_id, roster)
          map[session_id] = silo_id if silo_id
        end
      end

      def find_silo_for_session(session_id, roster)
        roster.each_value do |silo_data|
          return silo_data['id'] if silo_data['id'] == session_id
        end
        current_silo
      end

      def session_ids
        windows = cache.instance_variable_get(:@windows)
        windows.each_value.flat_map { |window| window[:costs].keys }.uniq
      end

      def band_color(ratio, active_count)
        Dude::Transcript::Band.new(ratio, active_count).color
      end
    end
  end
end
