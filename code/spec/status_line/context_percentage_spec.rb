require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/context_percentage'

describe Dude::StatusLine::ContextPercentage do
  include RR::DSL

  let(:sut) { described_class.new(session) }

  def stub_env_window(value)
    stub(ENV).[] do |key|
      key == 'CLAUDE_CODE_AUTO_COMPACT_WINDOW' ? value : nil
    end
  end

  describe '#value with dynamic window' do
    context 'when ENV[CLAUDE_CODE_AUTO_COMPACT_WINDOW] is set' do
      it 'uses env value with tokens to calculate percentage' do
        stub_env_window('100000')
        session = {
          'context_window' => {
            'total_input_tokens' => 50000,
            'total_output_tokens' => 34000,
            'context_window_size' => 200000
          }
        }
        sut = described_class.new(session)
        expect(sut.value).to eq(84)
      end
    end

    context 'when env is not set but context_window_size is present' do
      it 'uses context_window_size from session' do
        stub_env_window(nil)
        session = {
          'context_window' => {
            'total_input_tokens' => 40000,
            'total_output_tokens' => 60000,
            'context_window_size' => 100000
          }
        }
        sut = described_class.new(session)
        expect(sut.value).to eq(100)
      end
    end

    context 'when nothing is set' do
      it 'falls back to 200000 default' do
        stub_env_window(nil)
        session = {
          'context_window' => {
            'total_input_tokens' => 40000,
            'total_output_tokens' => 60000
          }
        }
        sut = described_class.new(session)
        expect(sut.value).to eq(50)
      end
    end

    context 'when env is 0 or invalid' do
      it 'skips env and uses context_window_size' do
        stub_env_window('0')
        session = {
          'context_window' => {
            'total_input_tokens' => 20000,
            'total_output_tokens' => 30000,
            'context_window_size' => 100000
          }
        }
        sut = described_class.new(session)
        expect(sut.value).to eq(50)
      end
    end

    context 'when context_window_size is 0 or missing' do
      it 'uses env value' do
        stub_env_window('100000')
        session = {
          'context_window' => {
            'total_input_tokens' => 25000,
            'total_output_tokens' => 75000
          }
        }
        sut = described_class.new(session)
        expect(sut.value).to eq(100)
      end
    end

    context 'when all three sources are present, uses the smallest' do
      it 'env < context_window_size < default' do
        stub_env_window('80000')
        session = {
          'context_window' => {
            'total_input_tokens' => 40000,
            'total_output_tokens' => 40000,
            'context_window_size' => 100000
          }
        }
        sut = described_class.new(session)
        expect(sut.value).to eq(100)
      end
    end

    context 'when no tokens are present' do
      it 'falls back to used_percentage from session' do
        stub_env_window(nil)
        session = {
          'context_window' => {
            'used_percentage' => 42
          }
        }
        sut = described_class.new(session)
        expect(sut.value).to eq(42)
      end
    end
  end
end
