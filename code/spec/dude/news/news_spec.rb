require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/news'

describe Dude::News::News do
  let(:mock_gh) { instance_double(Dude::Helpers::Gh) }
  let(:news) { described_class.new(limit: limit, gh: mock_gh) }
  let(:limit) { 5 }

  before do
    ENV.delete('CC_VERSION')
  end

  after do
    ENV.delete('CC_VERSION')
  end

  describe '#run' do
    context 'with mock gh' do
      before do
        ENV['CC_VERSION'] = '1.0.0'
        allow(mock_gh).to receive(:run).with(
          "release list -R anthropics/claude-code --limit 1 --json tagName -q '.[0].tagName'"
        ).and_return('1.2.3')
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json conclusion -q '.[0].conclusion'"
        ).and_return('success')
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
        ).and_return('')
        allow(mock_gh).to receive(:run).with(
          "release list -R anthropics/claude-code --limit 5 --json tagName -q '.[].tagName'"
        ).and_return("v1.0.0\nv0.9.0\nv0.8.0")
      end

      it 'outputs installed and latest versions' do
        expect do
          news.run
        end.to output(include('Installed: 1.0.0, Latest: 1.2.3')).to_stdout
      end

      it 'outputs smoke test status' do
        expect { news.run }.to output(include('Smoke test: success')).to_stdout
      end

      it 'outputs releases up to limit' do
        expect { news.run }.to output(include('v1.0.0', 'v0.9.0')).to_stdout
      end

      it 'respects limit parameter' do
        limited = described_class.new(limit: 1, gh: mock_gh)
        allow(mock_gh).to receive(:run).with(
          "release list -R anthropics/claude-code --limit 1 --json tagName -q '.[].tagName'"
        ).and_return('v1.0.0')
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
        ).and_return('')
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
        allow(mock_gh).to receive(:run).with(
          "release list -R anthropics/claude-code --limit 1 --json tagName -q '.[0].tagName'"
        ).and_return('1.2.3')
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json conclusion -q '.[0].conclusion'"
        ).and_return('failure')
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
        ).and_return('12345')
        allow(mock_gh).to receive(:run).with(
          "release list -R anthropics/claude-code --limit 5 --json tagName -q '.[].tagName'"
        ).and_return('')
      end

      it 'outputs github actions link' do
        expect { news.run }.to output(
          include('https://github.com/UKGEPIC/dude/actions/runs/12345')
        ).to_stdout
      end
    end

    context 'uses default GithubSource when no gh provided' do
      let(:news) { described_class.new(limit: limit) }

      before do
        ENV['CC_VERSION'] = '2.0.0'
      end

      it 'initializes with GithubSource' do
        expect(news.instance_variable_get(:@source)).to be_a(Dude::News::GithubSource)
      end
    end

    context 'with missing CC_VERSION' do
      before do
        allow(mock_gh).to receive(:run).with(
          "release list -R anthropics/claude-code --limit 1 --json tagName -q '.[0].tagName'"
        ).and_return('1.0.0')
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json conclusion -q '.[0].conclusion'"
        ).and_return('success')
        allow(mock_gh).to receive(:run).with(
          "run list --repo UKGEPIC/dude --branch main --limit 1 --json databaseId -q '.[0].databaseId'"
        ).and_return('')
        allow(mock_gh).to receive(:run).with(
          "release list -R anthropics/claude-code --limit 5 --json tagName -q '.[].tagName'"
        ).and_return('')
      end

      it 'defaults to unknown' do
        expect { news.run }.to output(include('Installed: unknown')).to_stdout
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
