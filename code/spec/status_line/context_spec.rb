require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/context'
require_relative '../../lib/dude/dudes/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Context do
  include RR::DSL
  include_context 'StatusLine helpers'

  before { stub_const('Dude::StatusLine::Format::JETBRAINS', false) }

  describe '#to_s' do
    it 'returns 9-block bar' do
      sut = described_class.new(mock_session('opus', 0).to_json, 0)
      bar = Dude::StatusLine::Format.strip(sut.to_s)[/🧠 ([█░]+)/, 1]
      expect(bar.length).to eq(9)
    end

    describe 'filled blocks' do
      [
        [0, 0],
        [33, 3],
        [66, 6],
        [100, 9]
      ].each do |pct, filled|
        it "shows #{filled} filled at #{pct}%" do
          sut = described_class.new(mock_session('opus', pct).to_json, pct)
          bar = Dude::StatusLine::Format.strip(sut.to_s)[/🧠 ([█░]+)/, 1]
          expect(bar.count("█")).to eq(filled)
        end
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
