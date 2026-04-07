module Dude
  module StatusLine
    module Format
      COLORS = {
        red: "\033[31m",
        green: "\033[32m",
        yellow: "\033[38;5;226m",
        reset: "\033[0m",
        bg_green: "\033[42m",
        bg_red: "\033[41m",
        bg_yellow: "\033[48;5;226m"
      }

      SUPERSCRIPTS = {
        0 => '⁰', 1 => '¹', 2 => '²', 3 => '³', 4 => '⁴', 5 => '⁵', 6 => '⁶',
        7 => '⁷', 8 => '⁸', 9 => '⁹',
        10 => '¹⁰'
      }
      BG_MAP = {
        "\033[32m" => "\033[42m",
        "\033[38;5;226m" => "\033[48;5;226m",
        "\033[31m" => "\033[41m"
      }
      WHITE = "\033[97m"
      JETBRAINS = ENV['TERMINAL_EMULATOR'] == 'JetBrains-JediTerm'

      def clamp(value)
        [[value.to_i, 0].max, 100].min
      end

      def color_for_pct(pct, lo = 33, hi = 66)
        pct < lo ? COLORS[:green] : (pct <= hi ? COLORS[:yellow] : COLORS[:red])
      end

      def bar(pct, emoji, lo: 33, hi: 66, color: nil)
        filled = (clamp(pct) * 9 / 100.0).round
        col = color || color_for_pct(clamp(pct), lo, hi)
        pad = JETBRAINS ? ' ' : ''
        bars = "#{'█' * filled}#{'░' * (9 - filled)}"
        "#{col}#{emoji}#{pad} #{bars}#{COLORS[:reset]}"
      end

      def emoji_str(emoji, color, sup)
        pad = JETBRAINS ? ' ' : ''
        "#{color}#{emoji}#{pad}#{sup}#{COLORS[:reset]}"
      end

      def emoji_group(emoji, count, active, color)
        sup = count.is_a?(String) ? count : SUPERSCRIPTS[count] || '⁹⁺'
        pad = JETBRAINS ? ' ' : ''
        fg = color == COLORS[:yellow] ? "\033[30m" : WHITE
        active ? "#{BG_MAP[color]}#{fg}#{emoji}#{pad}#{sup}#{COLORS[:reset]}" :
               emoji_str(emoji, color, sup)
      end

      def percentage(part, total)
        total.zero? ? 0 : (part * 100 / total).round
      end

      def round_to_10(n)
        ((n + 5) / 10) * 10
      end

      def normalize_to_100(a, b, c)
        rounded = [a, b, c].map { |n| round_to_10(n) }
        rounded[[a, b, c].index([a, b, c].max)] += 100 - rounded.sum
        rounded
      end

      def self.strip(str)
        str.gsub(/\033\[[^m]*m/, '')
      end
    end
  end
end
