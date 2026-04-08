require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/news'

describe Dude::News::News do
  let(:news) { described_class.new(limit: limit) }
  let(:limit) { 5 }
  let(:mock_data_path) { '/tmp/dude_news_mock_data.json' }

  before do
    ENV.delete('DUDE_NEWS_MOCK')
    ENV.delete('DUDE_NEWS_MOCK_DATA')
    ENV.delete('CC_VERSION')
  end

  after do
    ENV.delete('DUDE_NEWS_MOCK')
    ENV.delete('DUDE_NEWS_MOCK_DATA')
  end

  describe '#run' do
    context 'with mock data' do
      before do
        allow(File).to receive(:exist?).with(mock_data_path).and_return(true)
        allow(File).to receive(:read).with(mock_data_path).and_return(
          JSON.generate(
            {
              'latest_version' => '1.2.3',
              'workflow_conclusion' => 'success',
              'releases' => ['v1.0.0', 'v0.9.0', 'v0.8.0']
            }
          )
        )
        ENV['DUDE_NEWS_MOCK'] = 'true'
        ENV['CC_VERSION'] = '1.0.0'
      end

      it 'outputs installed and latest versions' do
        expect {
          news.run
        }.to output(include('Installed: 1.0.0, Latest: 1.2.3')).to_stdout
      end

      it 'outputs smoke test status' do
        expect { news.run }.to output(include('Smoke test: success')).to_stdout
      end

      it 'outputs releases up to limit' do
        expect { news.run }.to output(include('v1.0.0')).to_stdout
        expect { news.run }.to output(include('v0.9.0')).to_stdout
      end

      it 'respects limit parameter for releases' do
        limited_news = described_class.new(limit: 1)
        allow(File).to receive(:exist?).with(mock_data_path).and_return(true)
        allow(File).to receive(:read).with(mock_data_path).and_return(
          JSON.generate(
            {
              'latest_version' => '1.2.3',
              'workflow_conclusion' => 'success',
              'releases' => ['v1.0.0', 'v0.9.0', 'v0.8.0']
            }
          )
        )
        output = StringIO.new
        allow($stdout).to receive(:write) { |str| output.write(str) }
        limited_news.run
        result = output.string
        expect(result).to include('v1.0.0')
        expect(result).not_to include('v0.9.0')
      end

      it 'outputs github actions link when conclusion is failure' do
        allow(File).to receive(:exist?).with(mock_data_path).and_return(true)
        allow(File).to receive(:read).with(mock_data_path).and_return(
          JSON.generate(
            {
              'latest_version' => '1.2.3',
              'workflow_conclusion' => 'failure',
              'run_url' => 'https://github.com/UKGEPIC/dude/actions/runs/12345',
              'releases' => []
            }
          )
        )
        failure_news = described_class.new(limit: 5)
        expect { failure_news.run }.to output(
          include('https://github.com/UKGEPIC/dude/actions/runs/12345')
        ).to_stdout
      end

      it 'does not output github link when conclusion is success' do
        expect { news.run }.not_to output(/github\.com/).to_stdout
      end
    end

    context 'without mock data' do
      before do
        ENV['CC_VERSION'] = '2.0.0'
      end

      it 'outputs unknown for latest version when no mock' do
        expect {
          news.run
        }.to output(include('Installed: 2.0.0, Latest: unknown')).to_stdout
      end

      it 'outputs unknown for smoke test when no mock' do
        expect { news.run }.to output(include('Smoke test: unknown')).to_stdout
      end

      it 'handles empty releases list' do
        expect { news.run }.not_to raise_error
      end
    end

    context 'with custom mock data path' do
      before do
        custom_path = '/custom/path/mock.json'
        ENV['DUDE_NEWS_MOCK_DATA'] = custom_path
        ENV['DUDE_NEWS_MOCK'] = 'true'
        allow(File).to receive(:exist?).with(custom_path).and_return(true)
        allow(File).to receive(:exist?).with(mock_data_path).and_return(false)
        allow(File).to receive(:read).with(custom_path).and_return(
          JSON.generate(
            {
              'latest_version' => '2.0.0',
              'workflow_conclusion' => 'success',
              'releases' => ['v2.0.0']
            }
          )
        )
        ENV['CC_VERSION'] = '1.5.0'
      end

      it 'reads from custom path when ENV set' do
        expect { news.run }.to output(include('Latest: 2.0.0')).to_stdout
      end
    end

    context 'with missing CC_VERSION env' do
      before do
        allow(File).to receive(:exist?).with(mock_data_path).and_return(true)
        allow(File).to receive(:read).with(mock_data_path).and_return(
          JSON.generate(
            {
              'latest_version' => '1.0.0',
              'workflow_conclusion' => 'success',
              'releases' => []
            }
          )
        )
        ENV['DUDE_NEWS_MOCK'] = 'true'
      end

      it 'defaults to unknown' do
        expect { news.run }.to output(include('Installed: unknown')).to_stdout
      end
    end
  end
end
