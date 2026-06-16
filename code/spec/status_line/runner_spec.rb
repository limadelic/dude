require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/runner'

describe Dude::StatusLine::Runner do
  describe 'context bar rendering' do
    let(:sut) { described_class.new(input.to_json) }

    context 'with token counts' do
      let(:input) do
        {
          'context_window' => {
            'total_input_tokens' => 124000,
            'total_output_tokens' => 0,
            'context_window_size' => 1000000,
            'used_percentage' => 12
          }
        }
      end

      it 'renders 6 filled blocks from tokens (62%)' do
        output = capture_output { sut.run }
        filled = strip(output).count('█')

        expect(filled).to eq(6)
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

      it 'renders 1 filled block from used_percentage (9%, min-fill)' do
        output = capture_output { sut.run }
        filled = strip(output).count('█')

        expect(filled).to eq(1)
      end
    end

    context 'with no context_window' do
      let(:input) { {} }

      it 'renders 0 filled blocks (0%)' do
        output = capture_output { sut.run }
        filled = strip(output).count('█')

        expect(filled).to eq(0)
      end
    end

    context 'with zero context_window_size' do
      let(:input) do
        {
          'context_window' => {
            'total_input_tokens' => 0,
            'total_output_tokens' => 0,
            'context_window_size' => 0,
            'used_percentage' => 9
          }
        }
      end

      it 'renders 1 filled block from fallback (9%, min-fill)' do
        output = capture_output { sut.run }
        filled = strip(output).count('█')

        expect(filled).to eq(1)
      end
    end
  end
end
