require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/context'
require_relative '../../lib/dude/dudes/dudes'
require_relative '../examples/shared'

describe Dude::StatusLine::Context do
  include_context 'StatusLine helpers'

  before do
    stub_const('Dude::StatusLine::Format::JETBRAINS', false)
    allow(Dude::Dudes::Dudes).to receive(:new).and_return(
      instance_double(
        Dude::Dudes::Dudes, all: []
      )
    )
  end

  describe 'Context bar' do
    it 'has 9 blocks' do
      output = output_for_context(25)
      expect(strip(output)[/🧠 ([█░]+)/, 1]&.length).to eq(9)
    end

    context 'fill based on percentage' do
      it 'shows 0 filled blocks at 0%' do
        output = output_for_context(0)
        expect(strip(output)[/🧠 ([█░]+)/, 1]&.count("█")).to eq(0)
      end

      it 'shows 3 filled blocks at 33%' do
        output = output_for_context(33)
        expect(strip(output)[/🧠 ([█░]+)/, 1]&.count("█")).to eq(3)
      end

      it 'shows 6 filled blocks at 66%' do
        output = output_for_context(66)
        expect(strip(output)[/🧠 ([█░]+)/, 1]&.count("█")).to eq(6)
      end

      it 'shows 9 filled blocks at 100%' do
        output = output_for_context(100)
        expect(strip(output)[/🧠 ([█░]+)/, 1]&.count("█")).to eq(9)
      end
    end

    describe 'color coding' do
      it 'is green at 25%' do
        expect(output_for_context(25)).to include("\e[32m🧠")
      end

      it 'is yellow at 50%' do
        expect(output_for_context(50)).to include("\e[38;5;226m🧠")
      end

      it 'is red at 80%' do
        expect(output_for_context(80)).to include("\e[31m🧠")
      end
    end
  end

  private

  def output_for_context(pct)
    session_with_context = mock_session('opus', pct)
    out(session_with_context.to_json, activity)
  end
end
