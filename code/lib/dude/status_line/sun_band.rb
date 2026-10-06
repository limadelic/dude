require_relative '../transcript/usage_cache_store'
require_relative '../transcript/silo_registry'
require_relative '../transcript/current_silo'
require_relative '../transcript/silo_usage'
require_relative '../transcript/band'
require_relative '../transcript/cache_staleness_checker'
require_relative '../transcript/scanner_spawner'
require_relative 'price_table'

module Dude
  module StatusLine
    class WindowBand
      DEFAULT_CACHE_PATH = '~/.claude/dude/usage_cache.json'

      def initialize(session_data, window:, cache: nil, registry: nil,
        cache_path: nil)
        @session = session_data
        @window = window
        @cache = cache
        @registry = registry
        @cache_path = cache_path || File.expand_path(DEFAULT_CACHE_PATH)
      end

      def call
        return nil if cache_is_stale?
        return nil unless current_silo

        band_for_silo(current_silo)
      rescue StandardError
        nil
      end

      private

      def cache_is_stale?
        return false unless check_staleness

        spawn_scanner
        true
      end

      def check_staleness
        checker = Dude::Transcript::CacheStalenessChecker.new(@cache_path)
        checker.stale?
      end

      def spawn_scanner
        Dude::Transcript::ScannerSpawner.new(@cache_path).spawn
      end

      def band_for_silo(silo_id)
        usage = silo_usage
        return nil if usage.active_count <= 1

        ratio = usage.ratio(silo_id)
        band_color(ratio, usage.active_count) if ratio
      end

      def current_silo
        @current_silo ||= Dude::Transcript::CurrentSilo.new(silo_registry).call(
          session_name: @session['session_name'],
          customTitle: @session['customTitle'],
          agentName: @session['agentName']
        )
      end

      def silo_registry
        @registry ||= Dude::Transcript::SiloRegistry.new.tap(&:load)
      end

      def silo_usage
        @silo_usage ||= Dude::Transcript::SiloUsage.new(
          cache_store, sessions_to_silos, @window
        )
      end

      def cache_store
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
        windows = cache_store.instance_variable_get(:@windows)
        windows.each_value.flat_map { |window| window[:costs].keys }.uniq
      end

      def band_color(ratio, active_count)
        Dude::Transcript::Band.new(ratio, active_count).color
      end
    end

    class SunBand < WindowBand
      def initialize(session_data, cache: nil, registry: nil,
        cache_path: nil)
        super(
          session_data,
          window: '5h',
          cache: cache,
          registry: registry,
          cache_path: cache_path
        )
      end
    end

    class WeekBand < WindowBand
      def initialize(session_data, cache: nil, registry: nil,
        cache_path: nil)
        super(
          session_data,
          window: '7d',
          cache: cache,
          registry: registry,
          cache_path: cache_path
        )
      end
    end
  end
end
