require 'json'
require_relative 'format'

module StatusLine
  class Dudes
    include Format

    COLOR_NAMES = { 'green' => 'green', 'yellow' => 'yellow', 'red' => 'red' }

    def initialize(session_data, dudes_data, dude_dir, context_percentage)
      @session = session_data.is_a?(String) ? JSON.parse(session_data) : session_data
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
      status = File.exist?(status_file) ? JSON.load_file(status_file) : {}
      status['color'] = color_name_for_percentage(@context_percentage)
      File.write(status_file, JSON.generate(status))
    end

    private

    def render_dude(dude)
      icon = dude.icon
      messages = dude.messages || 0
      context = dude.context || 0
      is_current = dude.is_current?
      is_abiding = dude.is_abiding?

      # Determine superscript: message count if abiding, 'ˣ' if not
      sup = is_abiding ? messages : 'ˣ'
      color = color_for_pct(context)

      emoji_group(icon, sup, is_current, color)
    end

    def color_name_for_percentage(percentage)
      case percentage
      when 0..32
        'green'
      when 33..66
        'yellow'
      else
        'red'
      end
    end
  end
end
