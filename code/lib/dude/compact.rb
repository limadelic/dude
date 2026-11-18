require_relative './compact/turn'

module Dude
  class Compact
    HEADER = "The human's own words before this compaction, newest last:"
    MONTHS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]

    def initialize(riley, asks)
      @riley = riley
      @asks = asks
    end

    def call
      [@riley, HEADER, *@asks.sort_by(&:time).map { |ask| row(ask) }].compact
    end

    private

    def row(ask)
      "#{stamp(ask.time.localtime)} #{ask.text}"
    end

    def stamp(time)
      "#{MONTHS[time.month - 1]} #{time.day} #{clock(time)}"
    end

    def clock(time)
      hour = time.hour % 12
      hour = 12 if hour.zero?
      format('%d:%02d %s', hour, time.min, time.hour < 12 ? 'AM' : 'PM')
    end
  end
end
