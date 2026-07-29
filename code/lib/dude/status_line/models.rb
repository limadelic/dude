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
        return '' unless transcript_path

        counts = request_counter.count(transcript_path)
        return '' if counts.empty?

        usage_share(counts)
      rescue StandardError
        ''
      end

      private

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

        is_current = current_model == model_name
        repeated = emoji * emoji_count

        if is_current
          "#{BG_MAP[COLORS[:green]]}#{WHITE}#{repeated}#{COLORS[:reset]}"
        else
          "#{COLORS[:green]}#{repeated}#{COLORS[:reset]}"
        end
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
