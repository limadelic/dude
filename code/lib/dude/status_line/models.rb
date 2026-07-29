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

        sorted_models = counts.sort_by { |_, count| -count }
        bars = sorted_models.map do |model_name, count|
          pct = percentage(count, total)
          emoji_count = (pct / 10.0).round
          render_model(model_name, emoji_count)
        end
        bars.join
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
