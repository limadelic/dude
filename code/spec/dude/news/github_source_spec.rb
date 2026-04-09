require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/paperboy'

describe Dude::News::Paperboy do
  let(:mock_gh) { instance_double(Dude::Helpers::Gh) }
  let(:source) { described_class.new(gh: mock_gh) }

  describe '#latest_version' do
    before do
      allow(mock_gh).to receive(:run).with(
        "release list -R anthropics/claude-code --limit 1 --json tagName -q '.[0].tagName'"
      ).and_return('v1.2.3')
    end

    it 'returns latest version from gh' do
      expect(source.latest_version).to eq('v1.2.3')
    end
  end

  describe '#releases' do
    before do
      allow(mock_gh).to receive(:run).with(
        "release list -R anthropics/claude-code --limit 3 --json tagName -q '.[].tagName'"
      ).and_return("v1.0.0\nv0.9.0\nv0.8.0")
    end

    it 'returns releases array with given limit' do
      expect(source.releases(3)).to eq(%w[v1.0.0 v0.9.0 v0.8.0])
    end
  end
end
