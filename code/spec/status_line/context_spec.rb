require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/context'
require_relative '../../lib/dude/dudes/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Context do
  include RR::DSL
  include_context 'StatusLine helpers'

  before { stub_const('Dude::StatusLine::Format::JETBRAINS', false) }

  describe '#to_s' do
    let(:sut) {
      described_class.new(mock_session('opus', percentage).to_json, percentage)
    }
    let(:bar) { Dude::StatusLine::Format.strip(sut.to_s)[/🧠 ([█░]+)/, 1] }

    context 'at 0%' do
      let(:percentage) { 0 }

      it 'returns 9-block bar' do
        expect(bar.length).to eq(9)
      end

      it 'shows 0 filled blocks' do
        expect(bar.count("█")).to eq(0)
      end
    end

    context 'at 33%' do
      let(:percentage) { 33 }

      it 'returns 9-block bar' do
        expect(bar.length).to eq(9)
      end

      it 'shows 3 filled blocks' do
        expect(bar.count("█")).to eq(3)
      end
    end

    context 'at 66%' do
      let(:percentage) { 66 }

      it 'returns 9-block bar' do
        expect(bar.length).to eq(9)
      end

      it 'shows 6 filled blocks' do
        expect(bar.count("█")).to eq(6)
      end
    end

    context 'at 100%' do
      let(:percentage) { 100 }

      it 'returns 9-block bar' do
        expect(bar.length).to eq(9)
      end

      it 'shows 9 filled blocks' do
        expect(bar.count("█")).to eq(9)
      end
    end

    describe 'color coding' do
      def output_at_percentage(pct)
        described_class.new(mock_session('opus', pct).to_json, pct).to_s
      end

      include_examples 'color threshold', 25, 50, 80
    end
  end
end
