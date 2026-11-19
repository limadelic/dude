module Dude
  module Transcript
    class SiloUsage
      def initialize(cache, sessions_to_silos, window)
        @cache = cache
        @sessions_to_silos = sessions_to_silos
        @window = window
      end

      def cost(silo_id)
        @sessions_to_silos.sum do |session_id, mapped_silo|
          mapped_silo == silo_id ? @cache.cost(@window, session_id) : 0
        end
      end

      def total_cost
        @sessions_to_silos.sum do |session_id, _|
          @cache.cost(@window, session_id)
        end
      end

      def active_count
        silo_costs_map.count { |_, c| c > 0 }
      end

      def ratio(silo_id)
        return nil if silo_id.nil?
        return nil if active_count == 0
        return nil if cost(silo_id) == 0

        average = silo_costs_map.values.sum / active_count.to_f
        cost(silo_id) / average
      end

      private

      def silo_costs_map
        @sessions_to_silos.reduce({}) do |costs, (session_id, silo_id)|
          costs[silo_id] =
            (costs[silo_id] || 0) + @cache.cost(@window, session_id) if silo_id
          costs
        end
      end
    end
  end
end
