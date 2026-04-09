require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/paperboy'

describe Dude::News::Paperboy do
  let(:gh) { instance_double(Dude::Helpers::Gh) }
  let(:paperboy) { described_class.new }

  before { allow(Dude::Helpers::Gh).to receive(:new).and_return(gh) }

  describe '#latest_version' do
    it 'asks gh for the latest release tag' do
      expect(gh).to receive(:run).with(
        "release list -R anthropics/claude-code --limit 1 --json tagName -q '.[0].tagName'"
      ).and_return('v1.2.3')

      result = paperboy.latest_version

      expect(result).to eq('v1.2.3')
    end
  end

  describe '#releases' do
    it 'splits gh output into release tag array' do
      expect(gh).to receive(:run).with(
        "release list -R anthropics/claude-code --limit 3 --json tagName -q '.[].tagName'"
      ).and_return("v1.0.0\nv0.9.0\nv0.8.0")

      result = paperboy.releases(3)

      expect(result).to eq(%w[v1.0.0 v0.9.0 v0.8.0])
    end

    it 'filters empty lines from gh output' do
      expect(gh).to receive(:run).with(
        "release list -R anthropics/claude-code --limit 3 --json tagName -q '.[].tagName'"
      ).and_return("v1.0.0\n\nv0.9.0\nv0.8.0")

      result = paperboy.releases(3)

      expect(result).to eq(%w[v1.0.0 v0.9.0 v0.8.0])
    end

    it 'respects the limit parameter' do
      expect(gh).to receive(:run).with(
        "release list -R anthropics/claude-code --limit 5 --json tagName -q '.[].tagName'"
      ).and_return("v1.0.0\nv0.9.0\nv0.8.0\nv0.7.0\nv0.6.0")

      result = paperboy.releases(5)

      expect(result).to eq(%w[v1.0.0 v0.9.0 v0.8.0 v0.7.0 v0.6.0])
    end
  end
end
