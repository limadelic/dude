require_relative 'format'
require_relative '../transcript/request_counter'

module Dude
  module StatusLine
    class Models
      include Dude::StatusLine::Format

      MODELS = [['haiku', '🐸'], ['opus', '🎭'], ['sonnet', '🎸'], ['fable', '🦄']]

      def initialize(session, activity_data)
        @session = session
        @activity_data = activity_data
      end

      def to_s
        transcript_path = @session.dig('transcript_path')
        return fallback_emoji unless transcript_path

        counts = request_counter.count(transcript_path)
        return fallback_emoji if counts.empty?

        usage_share(counts)
      rescue StandardError
        fallback_emoji
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

        emoji_counts = counts.sort_by { |_, c| -c }
          .map { |n, c| [n, ((c * 100 / total) / 10.0).round] }
        adjust_for_minimum_visibility(emoji_counts, counts)
          .map { |n, c| render_model(n, c) }.join
      end

      def adjust_for_minimum_visibility(emoji_counts, counts)
        filtered = emoji_counts.select { |m, _| counts[m] > 0 }
        adjusted = filtered.map { |n, c| [n, [c, 1].max] }

        current_sum = adjusted.map(&:last).sum
        if current_sum < 10
          (10 - current_sum).times { |i| adjusted[i % adjusted.size][1] += 1 }
        elsif current_sum > 10
          idx = 0
          (current_sum - 10).times do
            loop do
              if adjusted[idx % adjusted.size][1] > 1
                adjusted[idx % adjusted.size][1] -= 1
                idx += 1
                break
              end
              idx += 1
            end
          end
        end

        adjusted
      end

      def render_model(model_name, emoji_count)
        emoji = model_emoji(model_name)
        return '' unless emoji
        return '' if emoji_count.zero?

        is_current = current_model == model_name
        emoji_group(emoji, emoji_count, is_current, COLORS[:green])
      end

      def model_emoji(model_name)
        MODELS.find { |name, _| name == model_name }&.[](1)
      end

      def current_model
        model_id = @session.dig('model', 'id') || ''
        MODELS.find { |name, _| model_id.include?(name) }&.[](0)
      end
    end
  end
end
