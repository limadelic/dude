require_relative 'format'

module Dude
  module StatusLine
    class Models
      include Dude::StatusLine::Format

      MODELS = [['haiku', '🐸'], ['opus', '🎭'], ['sonnet', '🎸']]

      def initialize(session, activity_data)
        @session = session
        @activity_data = activity_data
      end

      def to_s
        stats = fetch_model_stats
        return "" if stats.empty? || model_counts(stats).sum.zero?

        build_model_groups(stats).sort_by { |g|
          -g[0]
        }.map { |g| emoji_group(*g[1..]) }.join(' ')
      end

      private

      def model_counts(stats) = MODELS.map { |m, _|
        sum_metric(stats, m, 'successful_requests').to_i
      }

      def model_costs(stats) = MODELS.map { |m, _|
        sum_metric(stats, m, 'spend')
      }

      def cost_pcts(costs)
        costs.map { |c| costs.sum.zero? ? 0 : (c * 100 / costs.sum).round }
      end

      def build_model_groups(stats)
        counts, costs = model_counts(stats), model_costs(stats)
        pcts = normalize_to_100(*counts.map { |c| percentage(c, counts.sum) })
        build_group_array(
          counts, pcts, cost_pcts(costs),
          @session.dig('model', 'id') || ''
        )
      end

      def build_group_array(counts, pcts, cpcts, current)
        MODELS.each_with_index.map { |(m, e), i|
          [
            counts[i], e, pcts[i] / 10, current.include?(m),
            color_for_pct(cpcts[i])
          ]
        }
      end

      def fetch_model_stats
        @activity_data.dig('results', 0, 'breakdown', 'models') || {}
      rescue StandardError
        {}
      end

      def sum_metric(groups, model_name, key)
        groups.select { |k, _| k.include?(model_name) }
          .sum { |_, v| v.dig('metrics', key).to_f }
      end
    end
  end
end
