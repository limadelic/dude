require_relative 'format'
require_relative '../transcript/request_counter'
require_relative '../model_families'

module Dude
  module StatusLine
    class Models
      include Dude::StatusLine::Format

      def initialize(session, activity_data)
        @session = session
        @activity_data = activity_data
      end

      def to_s
        counts = load_counts
        return fallback_emoji if counts.empty?

        usage_share(counts)
      rescue StandardError
        fallback_emoji
      end

      def load_counts
        transcript_path = @session.dig('transcript_path')
        return {} unless transcript_path

        request_counter.count(transcript_path)
      end

      private

      def fallback_emoji
        model_emoji(current_model) || ''
      end

      def request_counter
        Dude::Transcript::RequestCounter.new
      end

      def usage_share(counts)
        total = counts.values.sum
        return '' if total.zero?

        emoji_counts = sort_by_count_descending(counts, total)
        adjust_for_minimum_visibility(emoji_counts, counts)
          .map { |model_name, count| render_model(model_name, count) }.join
      end

      def sort_by_count_descending(counts, total)
        counts.sort_by { |_, count| -count }
          .each_with_object([]) do |(model_name, count), result|
            result << [model_name, percentage_rounded(count, total)]
          end
      end

      def percentage_rounded(count, total)
        ((count * 100 / total) / 10.0).round
      end

      def adjust_for_minimum_visibility(emoji_counts, counts)
        filtered = filter_with_usage(emoji_counts, counts)
        adjusted = add_minimums(filtered)
        rebalance_capacity(adjusted, adjusted.map(&:last).sum)
      end

      def filter_with_usage(emoji_counts, counts)
        emoji_counts.select { |model_name, _| has_usage(counts, model_name) }
      end

      def add_minimums(emoji_counts)
        emoji_counts.map { |model_name, count| with_minimum(model_name, count) }
      end

      def has_usage(counts, model_name)
        counts[model_name] > 0
      end

      def with_minimum(model_name, count)
        [model_name, [count, 1].max]
      end

      def rebalance_capacity(adjusted, current_sum)
        distribute_remaining_capacity(adjusted, current_sum) if current_sum < 10
        reduce_overflow_capacity(adjusted, current_sum) if current_sum > 10
        adjusted
      end

      def distribute_remaining_capacity(adjusted, current_sum)
        capacity = 10 - current_sum
        capacity.times { |i| adjusted[i % adjusted.size][1] += 1 }
      end

      def reduce_overflow_capacity(adjusted, current_sum)
        idx = 0
        (current_sum - 10).times do
          idx += 1 until adjusted[idx % adjusted.size][1] > 1
          adjusted[idx % adjusted.size][1] -= 1; idx += 1
        end
      end

      def render_model(model_name, emoji_count)
        emoji = model_emoji(model_name)
        return '' unless emoji
        return '' if emoji_count.zero?

        is_current = current_model == model_name
        emoji_group(emoji, emoji_count, is_current, COLORS[:green])
      end

      def model_emoji(model_name)
        Dude::ModelFamilies::ALL
          .find { |family_name, _emoji| family_name == model_name }
          &.[](1)
      end

      def current_model
        model_id = @session.dig('model', 'id') || ''
        Dude::ModelFamilies::ALL
          .find { |family_name, _emoji| model_id.include?(family_name) }
          &.[](0)
      end
    end
  end
end
