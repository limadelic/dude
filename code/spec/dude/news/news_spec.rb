require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/news'

describe Dude::News::News do
  let(:mock_paperboy) do
    instance_double(
      Dude::News::Paperboy,
      latest_version: '1.2.3',
      releases: %w[v1.0.0 v0.9.0 v0.8.0]
    )
  end
  let(:mock_sommelier) do
    instance_double(
      Dude::News::Sommelier,
      taste: { conclusion: 'success', url: nil, error: nil }
    )
  end
  let(:news) {
    described_class.new(
      limit: limit, paperboy: mock_paperboy,
      sommelier: mock_sommelier
    )
  }
  let(:limit) { 5 }

  before do
    ENV.delete('CC_VERSION')
  end

  after do
    ENV.delete('CC_VERSION')
  end

  describe '#fetch' do
    context 'with mock source' do
      before do
        ENV['CC_VERSION'] = '1.0.0'
      end

      it 'outputs installed and latest versions' do
        expect do
          news.fetch
        end.to output(include('Installed: 1.0.0, Latest: 1.2.3')).to_stdout
      end

      it 'outputs vintage result' do
        expect { news.fetch }.to output(include('Vintage 1.2.3: success')).to_stdout
      end

      it 'outputs releases up to limit' do
        expect { news.fetch }.to output(include('v1.0.0', 'v0.9.0')).to_stdout
      end

      it 'respects limit parameter' do
        limited_paperboy = instance_double(
          Dude::News::Paperboy,
          latest_version: '1.2.3',
          releases: %w[v1.0.0]
        )
        limited_sommelier = instance_double(
          Dude::News::Sommelier,
          taste: { conclusion: 'success', url: nil, error: nil }
        )
        limited = described_class.new(
          limit: 1, paperboy: limited_paperboy,
          sommelier: limited_sommelier
        )
        out = capture_stdout { limited.fetch }
        expect(out).to include('v1.0.0')
        expect(out).not_to include('v0.9.0')
      end
    end

    context 'uses default Paperboy and Sommelier when none provided' do
      let(:news) { described_class.new(limit: limit) }

      before do
        ENV['CC_VERSION'] = '2.0.0'
      end

      it 'initializes with Paperboy and Sommelier' do
        expect(news.instance_variable_get(:@paperboy)).to be_a(Dude::News::Paperboy)
        expect(news.instance_variable_get(:@sommelier)).to be_a(Dude::News::Sommelier)
      end
    end

    context 'with missing CC_VERSION' do
      before do
        ENV.delete('CC_VERSION')
      end

      let(:mock_paperboy) do
        instance_double(
          Dude::News::Paperboy,
          latest_version: '1.0.0',
          releases: []
        )
      end

      it 'defaults to unknown' do
        expect { news.fetch }.to output(include('Installed: unknown')).to_stdout
      end
    end
  end

  private

  def capture_stdout
    out = $stdout = StringIO.new
    yield
    out.string
  ensure
    $stdout = STDOUT
  end
end
