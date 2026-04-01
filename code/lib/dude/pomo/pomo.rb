require_relative '../status_line/format'

module Dude
  module Pomo
    class Pomo
      include Dude::StatusLine::Format

      POMO_TYPES = {
        'long break' => [900, '🍏', :green],
        'break' => [300, '🍏', :green],
        'default' => [1500, '🍅', :red]
      }

      def to_s
        label, end_time = read_pomo_file
        return nil unless end_time&.> Time.now.to_i

        render_bar(label, end_time)
      end

      def render_bar(label, end_time)
        total, icon, color_key = pomo_config(label)
        color = COLORS[color_key]
        bar(pomo_pct(total, end_time), icon, color: color) rescue nil
      end

      private

      def read_pomo_file
        path = ENV.fetch('POMO_STATUS_FILE', '/tmp/pomo.status')
        return nil unless File.exist?(path)

        parts = File.read(path).split('|')
        parts[0] != 'transitioning' && [parts[0], parts[1].to_i]
      end

      def pomo_config(label)
        return POMO_TYPES[label] if POMO_TYPES[label]

        key = label&.match?(/break/) ? 'break' : 'default'
        POMO_TYPES[key]
      end

      def pomo_pct(total, end_time)
        ((total - (end_time - Time.now.to_i)) * 100 / total).round
      end
    end
  end
end
