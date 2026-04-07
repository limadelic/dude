module Cuke
  class StatusLineResult
    ANCHORS = {
      '🧠' => 'Context', '💰' => 'Spend', '🍅' => 'Pomo', '🍏' => 'Pomo',
      '🐸' => 'Models', '🎭' => 'Models', '🎸' => 'Models'
    }

    Section = Struct.new(:raw, :cleaned)

    def initialize(raw)
      @raw = raw
      @cleaned = ::Dude::StatusLine::Format.strip(raw)
      @sections = group_atoms
    end

    def [](name)
      @sections[name] || Section.new('', '')
    end

    private

    def group_atoms
      pattern = /\[?\p{Emoji_Presentation}[^\p{Emoji_Presentation}\[]*/
      atoms = @cleaned.scan(pattern)
      groups = group_by_emoji(atoms)
      groups.transform_values { |parts| build_section(parts) }
    end

    def group_by_emoji(atoms)
      atoms.each_with_object({}) do |atom, hash|
        emoji = atom.match(/\p{Emoji_Presentation}/)[0]
        name = ANCHORS[emoji] || 'Dudes'
        (hash[name] ||= []) << atom
      end
    end

    def build_section(parts)
      cleaned = parts.join.strip
      first_pos, last_pos = find_positions(parts)
      return Section.new('', cleaned) unless first_pos && last_pos

      Section.new(
        extract_raw_window(first_pos, last_pos),
        bracket_bg_emojis(parts, cleaned)
      )
    end

    def find_positions(parts)
      [@raw.index(parts.first[0]), @raw.rindex(parts.last[0])]
    end

    def extract_raw_window(first_pos, last_pos)
      start_idx = [first_pos - 20, 0].max
      end_idx = [last_pos + 20, @raw.length - 1].min
      @raw[start_idx..end_idx]
    end

    def bracket_bg_emojis(parts, cleaned)
      section_start = @raw.index(parts.first[0])
      return cleaned unless section_start

      parts.inject(cleaned) do |result, part|
        apply_bracket_if_needed(result, part, section_start)
      end
    end

    def apply_bracket_if_needed(result, part, section_start)
      emoji_pos = find_emoji_position(part, section_start)
      return result unless emoji_pos

      return result unless has_background_before_emoji?(emoji_pos)

      bracket_part_in_result(result, part)
    end

    def find_emoji_position(part, section_start)
      emoji = part.match(/\p{Emoji_Presentation}/)[0]
      @raw.index(emoji, section_start)
    end

    def has_background_before_emoji?(emoji_pos)
      bg_codes = ["\033[41m", "\033[42m", "\033[48;5;226m"]
      last_reset = @raw[0...emoji_pos].rindex("\033[0m") || -1
      before_emoji_seq = @raw[last_reset + 1...emoji_pos]
      bg_codes.any? { |code| before_emoji_seq.include?(code) }
    end

    def bracket_part_in_result(result, part)
      part_stripped = part.gsub(/\s+$/, '')
      match = result.match(/#{Regexp.escape(part_stripped)}/)
      return result unless match

      result[0...match.begin(0)] + "[#{match[0]}]" + result[match.end(0)..]
    end
  end
end
