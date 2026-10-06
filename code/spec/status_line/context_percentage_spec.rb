require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/context_percentage'

describe Dude::StatusLine::ContextPercentage do
  include RR::DSL

  let(:sut) { described_class.new(session) }

  let(:env_window) { nil }
  let(:total_input_tokens) { nil }
  let(:context_window_size) { nil }
  let(:used_percentage) { nil }

  let(:session) do
    ctx = {}
    ctx['total_input_tokens'] = total_input_tokens if total_input_tokens
    ctx['context_window_size'] = context_window_size if context_window_size
    ctx['used_percentage'] = used_percentage if used_percentage
    { 'context_window' => ctx }
  end

  before do
    stub(ENV).[] do |key|
      key == 'CLAUDE_CODE_AUTO_COMPACT_WINDOW' ? env_window : nil
    end
  end

  describe '#value with dynamic window' do
    context 'window 100_000, input_tokens 63_650 equals 95%' do
      let(:env_window) { '100000' }
      let(:total_input_tokens) { 63650 }
      let(:context_window_size) { 200000 }

      it 'calculates as (100000 - 33000) threshold' do
        expect(sut.value).to eq(95)
      end
    end

    context 'window 200_000, input_tokens 83_500 equals 50%' do
      let(:total_input_tokens) { 83500 }
      let(:context_window_size) { 200000 }

      it 'calculates as (200000 - 33000) threshold' do
        expect(sut.value).to eq(50)
      end
    end

    context 'when env is 0 or invalid' do
      let(:env_window) { '0' }
      let(:total_input_tokens) { 20000 }
      let(:context_window_size) { 100000 }

      it 'skips env and uses context_window_size' do
        expect(sut.value).to eq(29)
      end
    end

    context 'when context_window_size is 0 or missing' do
      let(:env_window) { '100000' }
      let(:total_input_tokens) { 25000 }

      it 'uses env value' do
        expect(sut.value).to eq(37)
      end
    end

    context 'when all three sources are present, uses the smallest' do
      let(:env_window) { '80000' }
      let(:total_input_tokens) { 40000 }
      let(:context_window_size) { 100000 }

      it 'env < context_window_size < default' do
        expect(sut.value).to eq(85)
      end
    end

    context 'when no tokens are present' do
      let(:used_percentage) { 42 }

      it 'falls back to used_percentage from session' do
        expect(sut.value).to eq(42)
      end
    end
  end
end
