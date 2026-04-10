require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/format'

describe Dude::StatusLine::Format do
  include RR::DSL

  let(:sut) { Class.new { include Dude::StatusLine::Format }.new }
  let(:green) { Dude::StatusLine::Format::COLORS[:green] }
  let(:yellow) { Dude::StatusLine::Format::COLORS[:yellow] }
  let(:red) { Dude::StatusLine::Format::COLORS[:red] }
  let(:reset) { Dude::StatusLine::Format::COLORS[:reset] }

  def with_jetbrains(value)
    original = ENV['TERMINAL_EMULATOR'] == 'JetBrains-JediTerm'
    Dude::StatusLine::Format.send(:remove_const, :JETBRAINS)
    Dude::StatusLine::Format.const_set(:JETBRAINS, value)
    yield
  ensure
    Dude::StatusLine::Format.send(:remove_const, :JETBRAINS)
    Dude::StatusLine::Format.const_set(:JETBRAINS, original)
  end

  describe '#clamp' do
    it 'clamps values below 0 to 0' do
      expect(sut.clamp(-10)).to eq(0)
    end

    it 'clamps values above 100 to 100' do
      expect(sut.clamp(150)).to eq(100)
    end

    it 'leaves values in range unchanged' do
      expect(sut.clamp(50)).to eq(50)
    end
  end

  describe '#color_for_pct' do
    it 'returns green for low percentage' do
      expect(sut.color_for_pct(25)).to eq(green)
    end

    it 'returns yellow for mid percentage' do
      expect(sut.color_for_pct(50)).to eq(yellow)
    end

    it 'returns red for high percentage' do
      expect(sut.color_for_pct(75)).to eq(red)
    end
  end

  describe '#percentage' do
    it 'calculates percentage of part to total' do
      expect(sut.percentage(25, 100)).to eq(25)
    end

    it 'returns 0 for zero total' do
      expect(sut.percentage(10, 0)).to eq(0)
    end
  end

  describe '#round_to_10' do
    it 'rounds down when remainder < 5' do
      expect(sut.round_to_10(12)).to eq(10)
    end

    it 'rounds up when remainder >= 5' do
      expect(sut.round_to_10(15)).to eq(20)
    end
  end

  describe '#normalize_to_100' do
    it 'distributes remainder to largest value' do
      result = sut.normalize_to_100(30, 30, 30)
      expect(result.sum).to eq(100)
    end

    it 'preserves largest value detection' do
      result = sut.normalize_to_100(10, 50, 30)
      expect(result[1]).to be > 50
    end
  end

  describe '#bar' do
    it 'renders emoji with filled blocks' do
      result = sut.bar(50, '🧠')
      expect(result).to include('🧠')
      expect(result).to include('█')
      expect(result).to include('░')
    end

    it 'uses custom lo and hi thresholds' do
      result = sut.bar(40, '🎯', lo: 50, hi: 75)
      expect(result).to include("\e[32m")
    end

    it 'uses provided color instead of calculated' do
      result = sut.bar(25, '💰', color: red)
      expect(result).to include("\e[31m")
    end

    context 'emoji and bars spacing' do
      it 'has no extra space between emoji and bars when NOT JetBrains' do
        with_jetbrains(false) do
          result = sut.bar(50, '🧠')
          stripped = result.gsub(/\033\[[^m]*m/, '')
          expect(stripped).to match(/^🧠 [█░]+$/)
        end
      end

      it 'has extra space between emoji and bars when IS JetBrains' do
        with_jetbrains(true) do
          result = sut.bar(50, '🧠')
          stripped = result.gsub(/\033\[[^m]*m/, '')
          expect(stripped).to match(/^🧠  [█░]+$/)
        end
      end
    end
  end

  describe '#emoji_str' do
    it 'formats emoji with color and superscript' do
      result = sut.emoji_str('🎭', green, '³')
      expect(result).to include('🎭')
      expect(result).to include('³')
      expect(result).to include("\e[32m")
    end

    context 'JetBrains emoji padding' do
      it 'returns string WITHOUT space between emoji and superscript when NOT JetBrains' do
        with_jetbrains(false) do
          result = sut.emoji_str('🎭', green, '³')
          stripped = result.gsub(/\033\[[^m]*m/, '')
          expect(stripped).to eq('🎭³')
        end
      end

      it 'returns string WITH space between emoji and superscript when IS JetBrains' do
        with_jetbrains(true) do
          result = sut.emoji_str('🎭', green, '³')
          stripped = result.gsub(/\033\[[^m]*m/, '')
          expect(stripped).to eq('🎭 ³')
        end
      end
    end
  end

  describe '#emoji_group' do
    context 'inactive emoji spacing' do
      it 'has no space when NOT JetBrains' do
        with_jetbrains(false) do
          result = sut.emoji_group('🎭', 5, false, green)
          stripped = result.gsub(/\033\[[^m]*m/, '')
          expect(stripped).to eq('🎭⁵')
        end
      end

      it 'has space when IS JetBrains' do
        with_jetbrains(true) do
          result = sut.emoji_group('🎭', 5, false, green)
          stripped = result.gsub(/\033\[[^m]*m/, '')
          expect(stripped).to eq('🎭 ⁵')
        end
      end
    end

    context 'active emoji spacing' do
      it 'has no space when NOT JetBrains' do
        with_jetbrains(false) do
          result = sut.emoji_group('🎭', 5, true, green)
          stripped = result.gsub(/\033\[[^m]*m/, '')
          expect(stripped).to eq('🎭⁵')
        end
      end

      it 'has space when IS JetBrains' do
        with_jetbrains(true) do
          result = sut.emoji_group('🎭', 5, true, green)
          stripped = result.gsub(/\033\[[^m]*m/, '')
          expect(stripped).to eq('🎭 ⁵')
        end
      end
    end

    it 'formats inactive emoji' do
      result = sut.emoji_group('🎭', 5, false, green)
      expect(result).to include('🎭')
      expect(result).to include('⁵')
    end

    it 'adds background for active emoji' do
      result = sut.emoji_group('🎭', 5, true, green)
      expect(result).to include("\e[42m")
    end

    it 'uses black text on yellow' do
      result = sut.emoji_group('🎭', 5, true, yellow)
      expect(result).to include("\e[30m")
    end

    it 'uses white text on other colors' do
      result = sut.emoji_group('🎭', 5, true, green)
      expect(result).to include("\e[97m")
    end
  end
end
