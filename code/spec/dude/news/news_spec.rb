require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/news'

describe Dude::News::News do
  let(:mock_source) do
    instance_double(Dude::News::GithubSource,
      latest_version: '1.2.3',
      workflow_conclusion: 'success',
      run_url: nil,
      releases: %w[v1.0.0 v0.9.0 v0.8.0]
    )
  end
  let(:news) { described_class.new(limit: limit, source: mock_source) }
  let(:limit) { 5 }

  before do
    ENV.delete('CC_VERSION')
  end

  after do
    ENV.delete('CC_VERSION')
  end

  describe '#run' do
    context 'with mock source' do
      before do
        ENV['CC_VERSION'] = '1.0.0'
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
        limited_source = instance_double(Dude::News::GithubSource,
          latest_version: '1.2.3',
          workflow_conclusion: 'success',
          run_url: nil,
          releases: %w[v1.0.0]
        )
        limited = described_class.new(limit: 1, source: limited_source)
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
      end

      let(:mock_source) do
        instance_double(Dude::News::GithubSource,
          latest_version: '1.2.3',
          workflow_conclusion: 'failure',
          run_url: 'https://github.com/UKGEPIC/dude/actions/runs/12345',
          releases: []
        )
      end

      it 'outputs github actions link' do
        expect { news.run }.to output(
          include('https://github.com/UKGEPIC/dude/actions/runs/12345')
        ).to_stdout
      end
    end

    context 'uses default GithubSource when no source provided' do
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
        ENV.delete('CC_VERSION')
      end

      let(:mock_source) do
        instance_double(Dude::News::GithubSource,
          latest_version: '1.0.0',
          workflow_conclusion: 'success',
          run_url: nil,
          releases: []
        )
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
