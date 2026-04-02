require 'json'
require_relative 'format'

module Dude
  module StatusLine
    class Dudes
      include Dude::StatusLine::Format

      COLOR_NAMES = { 'green' => 'green', 'yellow' => 'yellow', 'red' => 'red' }

      def initialize(session_data, dudes_data, dude_dir, context_percentage)
        @session = parse_session(session_data)
        @dudes = dudes_data || []
        @dude_dir = dude_dir
        @context_percentage = context_percentage
      end

      def to_s
        return '' if @dudes.empty?

        @dudes.map { |dude| render_dude(dude) }.join(' ')
      end

      def write_status
        return unless Dir.exist?(@dude_dir)

        status_file = File.join(@dude_dir, 'status.json')
        status = load_status(status_file)
        status['color'] = color_name_for_percentage(@context_percentage)
        File.write(status_file, JSON.generate(status))
      end

      private

      def parse_session(session_data)
        return session_data unless session_data.is_a?(String)

        JSON.parse(session_data) rescue {}
      end

      def render_dude(dude)
        sup = dude.is_abiding? ? (dude.messages || 0) : 'ˣ'
        color = color_for_pct(dude.context || 0)
        emoji_group(dude.icon, sup, dude.is_current?, color)
      end

      def color_name_for_percentage(percentage)
        case percentage
        when 0..32 then 'green'
        when 33..66 then 'yellow'
        else 'red'
        end
      end

      def load_status(status_file)
        return {} unless File.exist?(status_file)

        JSON.load_file(status_file) rescue {}
      end
    end
  end
end
