require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/news'

describe Dude::News::News do
  let(:news) { described_class.new(limit: limit) }
  let(:limit) { 5 }
  let(:mock_path) { '/tmp/dude_news_test_mock.json' }

  before do
    ENV.delete('DUDE_NEWS_MOCK')
    ENV.delete('DUDE_NEWS_MOCK_DATA')
    ENV.delete('CC_VERSION')
  end

  after do
    ENV.delete('DUDE_NEWS_MOCK')
    ENV.delete('DUDE_NEWS_MOCK_DATA')
    File.delete(mock_path) if File.exist?(mock_path)
  end

  def write_mock(data)
    ENV['DUDE_NEWS_MOCK'] = 'true'
    ENV['DUDE_NEWS_MOCK_DATA'] = mock_path
    File.write(mock_path, JSON.generate(data))
  end

  describe '#run' do
    context 'with mock data' do
      before do
        ENV['CC_VERSION'] = '1.0.0'
        write_mock(
          'latest_version' => '1.2.3',
          'workflow_conclusion' => 'success',
          'releases' => %w[v1.0.0 v0.9.0 v0.8.0]
        )
      end

      it 'outputs installed and latest versions' do
        expect { news.run }.to output(include('Installed: 1.0.0, Latest: 1.2.3')).to_stdout
      end

      it 'outputs smoke test status' do
        expect { news.run }.to output(include('Smoke test: success')).to_stdout
      end

      it 'outputs releases up to limit' do
        expect { news.run }.to output(include('v1.0.0', 'v0.9.0')).to_stdout
      end

      it 'respects limit parameter' do
        limited = described_class.new(limit: 1)
        out = capture_stdout { limited.run }
        expect(out).to include('v1.0.0')
        expect(out).not_to include('v0.9.0')
      end

      it 'does not output github link on success' do
        expect { news.run }.not_to output(/github\.com/).to_stdout
      end
    end

    context 'when smoke test fails' do
      before do
        ENV['CC_VERSION'] = '1.0.0'
        write_mock(
          'latest_version' => '1.2.3',
          'workflow_conclusion' => 'failure',
          'run_url' => 'https://github.com/UKGEPIC/dude/actions/runs/12345',
          'releases' => []
        )
      end

      it 'outputs github actions link' do
        expect { news.run }.to output(
          include('https://github.com/UKGEPIC/dude/actions/runs/12345')
        ).to_stdout
      end
    end

    context 'without mock data' do
      before { ENV['CC_VERSION'] = '2.0.0' }

      it 'defaults latest to unknown' do
        expect { news.run }.to output(include('Installed: 2.0.0, Latest: unknown')).to_stdout
      end

      it 'defaults smoke test to unknown' do
        expect { news.run }.to output(include('Smoke test: unknown')).to_stdout
      end

      it 'handles empty releases' do
        expect { news.run }.not_to raise_error
      end
    end

    context 'with missing CC_VERSION' do
      before do
        write_mock(
          'latest_version' => '1.0.0',
          'workflow_conclusion' => 'success',
          'releases' => []
        )
      end

      it 'defaults to unknown' do
        expect { news.run }.to output(include('Installed: unknown')).to_stdout
      end
    end
  end

  private

  def capture_stdout
    out = StringIO.new
    $stdout = out
    yield
    out.string
  ensure
    $stdout = STDOUT
  end
end
