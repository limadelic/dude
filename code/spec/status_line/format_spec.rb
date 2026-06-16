require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/format'

describe Dude::StatusLine::Format do
  include RR::DSL

  let(:sut) { Class.new { include Dude::StatusLine::Format }.new }
  let(:green) { Dude::StatusLine::Format::COLORS[:green] }
  let(:yellow) { Dude::StatusLine::Format::COLORS[:yellow] }
  let(:red) { Dude::StatusLine::Format::COLORS[:red] }
  let(:reset) { Dude::StatusLine::Format::COLORS[:reset] }
  let(:white) { Dude::StatusLine::Format::WHITE }
  let(:bg_green) { Dude::StatusLine::Format::COLORS[:bg_green] }

  describe '#clamp' do
    it 'returns 0 for negative values' do
      expect(sut.clamp(-10)).to eq(0)
    end

    it 'returns 100 for values above 100' do
      expect(sut.clamp(150)).to eq(100)
    end

    it 'returns value when between 0 and 100' do
      expect(sut.clamp(50)).to eq(50)
    end

    it 'returns 0 for exactly 0' do
      expect(sut.clamp(0)).to eq(0)
    end

    it 'returns 100 for exactly 100' do
      expect(sut.clamp(100)).to eq(100)
    end
  end

  describe '#color_for_pct' do
    it 'returns green below threshold' do
      expect(sut.color_for_pct(25)).to eq(green)
    end

    it 'returns green at lower threshold minus 1' do
      expect(sut.color_for_pct(32)).to eq(green)
    end

    it 'returns yellow above lower threshold' do
      expect(sut.color_for_pct(50)).to eq(yellow)
    end

    it 'returns yellow at upper threshold' do
      expect(sut.color_for_pct(66)).to eq(yellow)
    end

    it 'returns red above upper threshold' do
      expect(sut.color_for_pct(75)).to eq(red)
    end

    it 'returns red at high value' do
      expect(sut.color_for_pct(100)).to eq(red)
    end

    it 'returns green for 0' do
      expect(sut.color_for_pct(0)).to eq(green)
    end
  end

  describe '#percentage' do
    it 'calculates simple percentage' do
      expect(sut.percentage(25, 100)).to eq(25)
    end

    it 'returns 0 when total is zero' do
      expect(sut.percentage(10, 0)).to eq(0)
    end

    it 'rounds percentage correctly' do
      expect(sut.percentage(1, 3)).to eq(33)
    end

    it 'calculates percentage for half' do
      expect(sut.percentage(50, 100)).to eq(50)
    end
  end

  describe '#round_to_10' do
    it 'rounds down when remainder less than 5' do
      expect(sut.round_to_10(12)).to eq(10)
    end

    it 'rounds up when remainder >= 5' do
      expect(sut.round_to_10(15)).to eq(20)
    end

    it 'returns 0 for 0' do
      expect(sut.round_to_10(0)).to eq(0)
    end

    it 'rounds 5 up to 10' do
      expect(sut.round_to_10(5)).to eq(10)
    end

    it 'rounds 4 down to 0' do
      expect(sut.round_to_10(4)).to eq(0)
    end

    it 'rounds 24 to 20' do
      expect(sut.round_to_10(24)).to eq(20)
    end

    it 'rounds 25 to 30' do
      expect(sut.round_to_10(25)).to eq(30)
    end
  end

  describe '#normalize_to_100' do
    it 'ensures sum equals 100' do
      expect(sut.normalize_to_100(30, 30, 30).sum).to eq(100)
    end

    it 'increases largest value by remainder' do
      expect(sut.normalize_to_100(10, 50, 30)[1]).to be > 50
    end

    it 'rounds all values to nearest 10' do
      expect(
        sut.normalize_to_100(33, 33, 33).all? { |v|
          v % 10 == 0
        }
      ).to eq(true)
    end
  end

  describe '#bar' do
    it 'includes emoji in output' do
      result = sut.bar(50, '🧠')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to include('🧠')
    end

    it 'includes filled blocks' do
      result = sut.bar(50, '🧠')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to include('█')
    end

    it 'includes empty blocks' do
      result = sut.bar(50, '🧠')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to include('░')
    end

    it 'applies green color for low values' do
      result = sut.bar(10, '🎯')
      expect(result).to include(green)
    end

    it 'applies custom color when provided' do
      result = sut.bar(25, '💰', color: red)
      expect(result).to include(red)
    end

    it 'overrides color calculation with explicit color' do
      result = sut.bar(40, '🎯', lo: 50, hi: 75, color: red)
      expect(result).to include(red)
    end

    it 'respects custom lo threshold' do
      result = sut.bar(40, '🎯', lo: 50, hi: 75)
      expect(result).to include(green)
    end

    it 'checks spacing between emoji and bars' do
      result = sut.bar(50, '🧠')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to match(/🧠 +[█░]+/)
    end

    it 'shows 0 blocks at 0%' do
      result = sut.bar(0, '🧠')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped.count('█')).to eq(0)
    end

    it 'shows at least 1 block for small nonzero pct' do
      result = sut.bar(3, '🧠')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped.count('█')).to be >= 1
    end
  end

  describe '#emoji_str' do
    it 'includes emoji in output' do
      result = sut.emoji_str('🎭', green, '³')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to include('🎭')
    end

    it 'includes superscript in output' do
      result = sut.emoji_str('🎭', green, '³')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to include('³')
    end

    it 'includes color code' do
      result = sut.emoji_str('🎭', green, '³')
      expect(result).to include(green)
    end

    it 'includes reset code' do
      result = sut.emoji_str('🎭', green, '³')
      expect(result).to include(reset)
    end

    it 'handles spacing between emoji and superscript' do
      result = sut.emoji_str('🎭', green, '³')
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to match(/🎭 *³/)
    end
  end

  describe '#emoji_group' do
    describe 'inactive emoji' do
      it 'formats with emoji and superscript' do
        result = sut.emoji_group('🎭', 5, false, green)
        stripped = Dude::StatusLine::Format.strip(result)
        expect(stripped).to match(/🎭 *⁵/)
      end

      it 'includes color code' do
        result = sut.emoji_group('🎭', 5, false, green)
        expect(result).to include(green)
      end
    end

    describe 'active emoji' do
      it 'formats with emoji and superscript' do
        result = sut.emoji_group('🎭', 5, true, green)
        stripped = Dude::StatusLine::Format.strip(result)
        expect(stripped).to match(/🎭 *⁵/)
      end

      it 'includes background color' do
        result = sut.emoji_group('🎭', 5, true, green)
        expect(result).to include(bg_green)
      end

      it 'uses black text on yellow background' do
        result = sut.emoji_group('🎭', 5, true, yellow)
        expect(result).to include("\e[30m")
      end

      it 'uses white text on green background' do
        result = sut.emoji_group('🎭', 5, true, green)
        expect(result).to include(white)
      end

      it 'uses white text on red background' do
        result = sut.emoji_group('🎭', 5, true, red)
        expect(result).to include(white)
      end
    end

    it 'handles string count' do
      result = sut.emoji_group('🎭', '⁹⁺', false, green)
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to include('⁹⁺')
    end

    it 'uses 9+ for count above 10' do
      result = sut.emoji_group('🎭', 15, false, green)
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to include('⁹⁺')
    end

    it 'uses exact superscript for count 0-10' do
      result = sut.emoji_group('🎭', 0, false, green)
      stripped = Dude::StatusLine::Format.strip(result)
      expect(stripped).to include('⁰')
    end
  end

  describe '.strip' do
    it 'removes ANSI codes' do
      expect(Dude::StatusLine::Format.strip("\e[32mtest\e[0m")).to eq('test')
    end

    it 'preserves non-ANSI text' do
      expect(Dude::StatusLine::Format.strip('plain text')).to eq('plain text')
    end

    it 'removes multiple ANSI codes' do
      expect(Dude::StatusLine::Format.strip("\e[32m🎭\e[42m⁵\e[0m")).to eq('🎭⁵')
    end
  end
end
