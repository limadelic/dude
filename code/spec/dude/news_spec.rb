require 'spec_helper'
require 'dude/news/news'

describe Dude::News::News do
  subject(:news) { described_class.new(limit: 5) }

  describe '#latest_version' do
    context 'when mocking is enabled' do
      before { ENV['DUDE_NEWS_MOCK'] = 'true' }
      after { ENV.delete('DUDE_NEWS_MOCK') }

      it 'reads from mock data' do
        allow(news).to receive(:fetch_mock_data).and_return(
          'latest_version' => 'v0.1.2'
        )
        expect(news.send(:latest_version)).to eq 'v0.1.2'
      end
    end

    context 'when mocking is disabled' do
      before { ENV.delete('DUDE_NEWS_MOCK') }

      it 'calls gh release list and returns tag' do
        allow(Open3).to receive(:capture3).and_return(
          ['v1.0.0', '', double(success?: true)]
        )
        expect(news.send(:latest_version)).to eq 'v1.0.0'
        cmd = "gh release list -R anthropics/claude-code --limit 1 " \
              "--json tagName -q '.[0].tagName'"
        expect(Open3).to have_received(:capture3).with(cmd)
      end
    end
  end

  describe '#releases' do
    context 'when mocking is enabled' do
      before { ENV['DUDE_NEWS_MOCK'] = 'true' }
      after { ENV.delete('DUDE_NEWS_MOCK') }

      it 'reads from mock data' do
        allow(news).to receive(:fetch_mock_data).and_return(
          'releases' => ['v0.1.0', 'v0.0.9']
        )
        expect(news.send(:releases)).to eq(['v0.1.0', 'v0.0.9'])
      end
    end

    context 'when mocking is disabled' do
      before { ENV.delete('DUDE_NEWS_MOCK') }

      it 'calls gh and returns array of tags' do
        output = "v1.0.0\nv0.9.9\nv0.9.8"
        allow(Open3).to receive(:capture3).and_return(
          [output, '', double(success?: true)]
        )
        expect(news.send(:releases)).to eq(['v1.0.0', 'v0.9.9', 'v0.9.8'])
        cmd = "gh release list -R anthropics/claude-code " \
              "--limit 5 --json tagName -q '.[].tagName'"
        expect(Open3).to have_received(:capture3).with(cmd)
      end
    end
  end

  describe '#workflow_conclusion' do
    context 'when mocking is enabled' do
      before { ENV['DUDE_NEWS_MOCK'] = 'true' }
      after { ENV.delete('DUDE_NEWS_MOCK') }

      it 'reads from mock data' do
        allow(news).to receive(:fetch_mock_data).and_return(
          'workflow_conclusion' => 'success'
        )
        expect(news.send(:workflow_conclusion)).to eq 'success'
      end
    end

    context 'when mocking is disabled' do
      before { ENV.delete('DUDE_NEWS_MOCK') }

      it 'calls gh and returns conclusion' do
        allow(Open3).to receive(:capture3).and_return(
          ['failure', '', double(success?: true)]
        )
        expect(news.send(:workflow_conclusion)).to eq 'failure'
        cmd = "gh run list --repo UKGEPIC/dude --branch main " \
              "--limit 1 --json conclusion -q '.[0].conclusion'"
        expect(Open3).to have_received(:capture3).with(cmd)
      end
    end
  end

  describe '#run_url' do
    context 'when mocking is enabled' do
      before { ENV['DUDE_NEWS_MOCK'] = 'true' }
      after { ENV.delete('DUDE_NEWS_MOCK') }

      it 'reads from mock data' do
        allow(news).to receive(:fetch_mock_data).and_return(
          'run_url' => 'https://github.com/UKGEPIC/dude/actions/runs/123'
        )
        expect(news.send(:run_url)).to eq 'https://github.com/UKGEPIC/dude/actions/runs/123'
      end
    end

    context 'when mocking is disabled' do
      before { ENV.delete('DUDE_NEWS_MOCK') }

      it 'calls gh and constructs URL from databaseId' do
        allow(Open3).to receive(:capture3).and_return(
          ['9876543210', '', double(success?: true)]
        )
        expected_url = 'https://github.com/UKGEPIC/dude/actions/runs/9876543210'
        expect(news.send(:run_url)).to eq expected_url
        cmd = "gh run list --repo UKGEPIC/dude --branch main " \
              "--limit 1 --json databaseId -q '.[0].databaseId'"
        expect(Open3).to have_received(:capture3).with(cmd)
      end
    end
  end
end
