require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/platform_detector'

describe Dude::Dudes::PlatformDetector do
  describe '.detect' do
    context 'single ruby file' do
      it 'returns :ruby' do
        expect(described_class.detect(['app.rb'])).to eq :ruby
      end
    end

    context 'single elixir file with .ex' do
      it 'returns :elixir' do
        expect(described_class.detect(['app.ex'])).to eq :elixir
      end
    end

    context 'single elixir file with .exs' do
      it 'returns :elixir' do
        expect(described_class.detect(['test.exs'])).to eq :elixir
      end
    end

    context 'single dotnet file' do
      it 'returns :dotnet' do
        expect(described_class.detect(['app.cs'])).to eq :dotnet
      end
    end

    context 'single node file with .ts' do
      it 'returns :node' do
        expect(described_class.detect(['index.ts'])).to eq :node
      end
    end

    context 'single node file with .js' do
      it 'returns :node' do
        expect(described_class.detect(['index.js'])).to eq :node
      end
    end

    context 'multiple ruby files' do
      it 'returns :ruby' do
        expect(described_class.detect(['app.rb', 'lib.rb'])).to eq :ruby
      end
    end

    context 'multiple elixir files' do
      it 'returns :elixir' do
        expect(described_class.detect(['app.ex', 'test.exs'])).to eq :elixir
      end
    end

    context 'multiple node files' do
      it 'returns :node' do
        expect(described_class.detect(['index.ts', 'utils.js'])).to eq :node
      end
    end

    context 'unknown extension' do
      it 'raises error' do
        expect {
          described_class.detect(['app.py'])
        }.to raise_error(
          RuntimeError,
          /TCR only supports .rb, .ex, .exs, .cs, .ts, .js files/
        )
      end
    end

    context 'mixed platforms' do
      it 'raises error' do
        expect {
          described_class.detect(['app.rb', 'app.ex'])
        }.to raise_error(RuntimeError, /TCR files must be the same platform/)
      end
    end

    context 'empty files list' do
      it 'raises error' do
        expect {
          described_class.detect([])
        }.to raise_error(RuntimeError, /TCR requires at least one file/)
      end
    end
  end
end
