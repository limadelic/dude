require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/context'
require_relative '../../lib/dude/dudes/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Context do
  include RR::DSL
  include_context 'StatusLine helpers'

  let(:sut) { described_class.new(session, pct) }
  let(:pct) { 25 }
  let(:session) { mock_session('opus', pct).to_json }

  before { stub_const('Dude::StatusLine::Format::JETBRAINS', false) }

  describe 'Context bar' do
    it 'has 9 blocks' do
      result = strip(sut.to_s)[/🧠 ([█░]+)/, 1]&.length
      expect(result).to eq(9)
    end

    context 'fill based on percentage' do
      it 'shows 0 filled blocks at 0%' do
        sut_with_pct = described_class.new(mock_session('opus', 0).to_json, 0)
        result = strip(sut_with_pct.to_s)[/🧠 ([█░]+)/, 1]&.count("█")
        expect(result).to eq(0)
      end

      it 'shows 3 filled blocks at 33%' do
        sut_with_pct = described_class.new(mock_session('opus', 33).to_json, 33)
        result = strip(sut_with_pct.to_s)[/🧠 ([█░]+)/, 1]&.count("█")
        expect(result).to eq(3)
      end

      it 'shows 6 filled blocks at 66%' do
        sut_with_pct = described_class.new(mock_session('opus', 66).to_json, 66)
        result = strip(sut_with_pct.to_s)[/🧠 ([█░]+)/, 1]&.count("█")
        expect(result).to eq(6)
      end

      it 'shows 9 filled blocks at 100%' do
        sut_with_pct = described_class.new(mock_session('opus', 100).to_json, 100)
        result = strip(sut_with_pct.to_s)[/🧠 ([█░]+)/, 1]&.count("█")
        expect(result).to eq(9)
      end
    end

    describe 'color coding' do
      it 'is green at 25%' do
        expect(sut.to_s).to include("\e[32m🧠")
      end

      it 'is yellow at 50%' do
        sut_with_pct = described_class.new(mock_session('opus', 50).to_json, 50)
        expect(sut_with_pct.to_s).to include("\e[38;5;226m🧠")
      end

      it 'is red at 80%' do
        sut_with_pct = described_class.new(mock_session('opus', 80).to_json, 80)
        expect(sut_with_pct.to_s).to include("\e[31m🧠")
      end
    end
  end
end
