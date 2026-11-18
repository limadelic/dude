require_relative './compact/turn'

module Dude
  class Compact
    HEADER = "The human's own words before this compaction, newest last:"
    MONTHS = %w[Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec]
    LIMIT = 10_000
    NEWLINE = "\n"

    def initialize(riley, asks)
      @riley = riley
      @asks = asks
    end

    def call
      head = [@riley, HEADER].compact
      head + within(newest_rows, LIMIT - units(head.join(NEWLINE))).reverse
    end

    private

    def newest_rows
      @asks.sort_by(&:time).reverse.map { |ask| row(ask) }
    end

    def within(rows, budget)
      used = 0
      kept = rows.take_while { |row| (used += cost(row)) <= budget }
      return kept unless kept.empty?
      return [] unless rows.any?

      [cut(rows.first, budget - 1)].reject(&:empty?)
    end

    def cost(row)
      units(row) + 1
    end

    def cut(text, limit)
      used = 0
      text.each_char.take_while { |char| (used += width(char)) <= limit }.join
    end

    def units(text)
      text.each_char.sum { |char| width(char) }
    end

    def width(char)
      char.ord > 0xFFFF ? 2 : 1
    end

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
