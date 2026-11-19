require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/price_table'

describe Dude::StatusLine::PriceTable do
  include RR::DSL

  let(:rates) do
    {
      'opus' => {
        'input' => 5,
        'output' => 25,
        'cache_creation' => 6.25,
        'cache_read' => 0.5
      },
      'sonnet' => {
        'input' => 3,
        'output' => 15,
        'cache_creation' => 3.75,
        'cache_read' => 0.3
      },
      'haiku' => {
        'input' => 1,
        'output' => 5,
        'cache_creation' => 1.25,
        'cache_read' => 0.1
      }
    }
  end

  let(:usage) do
    {
      'input_tokens' => 0,
      'output_tokens' => 0,
      'cache_creation_input_tokens' => 0,
      'cache_read_input_tokens' => 0
    }
  end

  let(:sut) { Dude::StatusLine::PriceTable.new }

  before do
    stub(File).read { JSON.generate(rates) }
    stub(JSON).parse { rates }
  end

  describe '#cost' do
    context 'with opus model' do
      it 'calculates cost with input and output tokens' do
        usage['input_tokens'] = 1_000_000
        usage['output_tokens'] = 1_000_000

        cost = sut.cost('claude-opus-4-6', usage)

        expect(cost).to eq(30.0)
      end

      it 'applies cache creation rate' do
        usage['cache_creation_input_tokens'] = 1_000_000

        cost = sut.cost('claude-opus-4-6', usage)

        expect(cost).to eq(6.25)
      end

      it 'applies cache read rate' do
        usage['cache_read_input_tokens'] = 1_000_000

        cost = sut.cost('claude-opus-4-6', usage)

        expect(cost).to eq(0.5)
      end

      it 'combines all token types' do
        usage['input_tokens'] = 1_000_000
        usage['output_tokens'] = 1_000_000
        usage['cache_creation_input_tokens'] = 1_000_000
        usage['cache_read_input_tokens'] = 1_000_000

        cost = sut.cost('claude-opus-4-6', usage)

        expect(cost).to eq(36.75)
      end
    end

    context 'with sonnet model' do
      it 'applies sonnet input rate' do
        usage['input_tokens'] = 1_000_000

        cost = sut.cost('claude-sonnet-4-6', usage)

        expect(cost).to eq(3.0)
      end

      it 'applies sonnet output rate' do
        usage['output_tokens'] = 1_000_000

        cost = sut.cost('claude-sonnet-4-6', usage)

        expect(cost).to eq(15.0)
      end

      it 'applies sonnet cache creation rate' do
        usage['cache_creation_input_tokens'] = 1_000_000

        cost = sut.cost('claude-sonnet-4-6', usage)

        expect(cost).to eq(3.75)
      end

      it 'applies sonnet cache read rate' do
        usage['cache_read_input_tokens'] = 1_000_000

        cost = sut.cost('claude-sonnet-4-6', usage)

        expect(cost).to eq(0.3)
      end
    end

    context 'with haiku model' do
      it 'applies haiku input rate' do
        usage['input_tokens'] = 1_000_000

        cost = sut.cost('claude-haiku-4-5', usage)

        expect(cost).to eq(1.0)
      end

      it 'applies haiku output rate' do
        usage['output_tokens'] = 1_000_000

        cost = sut.cost('claude-haiku-4-5', usage)

        expect(cost).to eq(5.0)
      end

      it 'applies haiku cache creation rate' do
        usage['cache_creation_input_tokens'] = 1_000_000

        cost = sut.cost('claude-haiku-4-5', usage)

        expect(cost).to eq(1.25)
      end

      it 'applies haiku cache read rate' do
        usage['cache_read_input_tokens'] = 1_000_000

        cost = sut.cost('claude-haiku-4-5', usage)

        expect(cost).to eq(0.1)
      end
    end

    context 'with unknown model' do
      it 'uses opus rates' do
        usage['input_tokens'] = 1_000_000
        usage['output_tokens'] = 1_000_000

        cost = sut.cost('claude-unknown-model', usage)

        expect(cost).to eq(30.0)
      end

      it 'logs the model id' do
        expect { sut.cost('claude-unknown-model', usage) }
          .to output(/Unknown model: claude-unknown-model/).to_stderr
      end
    end

    context 'with missing usage keys' do
      it 'treats missing keys as zero' do
        cost = sut.cost('claude-opus-4-6', { 'input_tokens' => 1_000_000 })

        expect(cost).to eq(5.0)
      end

      it 'handles completely empty usage' do
        cost = sut.cost('claude-opus-4-6', {})

        expect(cost).to eq(0.0)
      end
    end

    context 'with fractional tokens' do
      it 'calculates fractional costs' do
        usage['input_tokens'] = 500_000
        usage['output_tokens'] = 500_000

        cost = sut.cost('claude-opus-4-6', usage)

        expect(cost).to eq(15.0)
      end
    end
  end
end
