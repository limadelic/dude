require_relative '../status_line/format'

module Pomo
  class Timer
    include StatusLine::Format

    POMO_TYPES = {
      'long break' => [900, '🍏', :green],
      'break' => [300, '🍏', :green],
      'default' => [1500, '🍅', :red]
    }.freeze

    def to_s
      label, end_time = read_pomo_file
      return nil unless end_time&.> Time.now.to_i
      render_bar(label, end_time)
    end

    def render_bar(label, end_time)
      total, icon, color_key = pomo_config(label)
      bar(pomo_pct(total, end_time), icon, color: COLORS[color_key]) rescue nil
    end

    private

    def read_pomo_file
      path = ENV.fetch('POMO_STATUS_FILE', '/tmp/pomo.status')
      return nil unless File.exist?(path)
      parts = File.read(path).split('|')
      parts[0] != 'transitioning' && [parts[0], parts[1].to_i]
    end

    def pomo_config(label)
      POMO_TYPES[label] || POMO_TYPES[label&.match?(/break/) ? 'break' : 'default']
    end

    def pomo_pct(total, end_time) = ((total - (end_time - Time.now.to_i)) * 100 / total).round
  end
end
