require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/runner'

describe Dude::StatusLine::Runner do
  describe '#context_percentage' do
    subject { described_class.new(input.to_json).send(:context_percentage) }

    context 'with token counts' do
      let(:input) do
        {
          'context_window' => {
            'total_input_tokens' => 100000,
            'total_output_tokens' => 2300,
            'context_window_size' => 200000,
            'used_percentage' => 9
          }
        }
      end

      it 'computes percentage from tokens' do
        expect(subject).to eq(51)
      end
    end

    context 'with fallback used_percentage' do
      let(:input) do
        {
          'context_window' => {
            'used_percentage' => 9
          }
        }
      end

      it 'uses used_percentage when tokens unavailable' do
        expect(subject).to eq(9)
      end
    end

    context 'with no context_window' do
      let(:input) { {} }

      it 'defaults to 0' do
        expect(subject).to eq(0)
      end
    end

    context 'with zero context_window_size' do
      let(:input) do
        {
          'context_window' => {
            'total_input_tokens' => 100000,
            'total_output_tokens' => 2300,
            'context_window_size' => 0,
            'used_percentage' => 9
          }
        }
      end

      it 'falls back to used_percentage' do
        expect(subject).to eq(9)
      end
    end
  end
end
