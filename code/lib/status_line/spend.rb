require_relative 'format'

class StatusLine::Spend
  include StatusLine::Format

  SPEND_CAP = ENV.fetch('CLAUDE_SPEND_CAP', '50').to_i

  def initialize(activity_data)
    @activity_data = activity_data
  end

  def render
    pct, min = spend_pct
    blocks = [pct * 9 / 100, min].max
    "#{color_for_pct(pct)}💰 #{'█' * blocks}#{'░' * (9 - blocks)}#{COLORS[:reset]}"
  end

  private

  def spend_pct
    spend = @activity_data.dig('results', 0, 'metrics', 'spend').to_f rescue 0
    [clamp((spend / SPEND_CAP * 100).round), spend > 0 ? 1 : 0]
  end
end
