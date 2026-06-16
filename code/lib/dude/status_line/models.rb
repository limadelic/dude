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
        model_id = @session.dig('model', 'id') || ''
        emoji = MODELS.find { |name, _| model_id.include?(name) }&.[](1)
        emoji || ''
      end
    end
  end
end
