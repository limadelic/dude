require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/paperboy'

describe Dude::News::Paperboy do
  let(:gh) { Object.new }
  let(:sut) { described_class.new(gh: gh) }

  describe '#latest_version' do
    it 'asks gh for the latest release tag' do
      cmd = 'release list -R anthropics/claude-code --limit 1 ' \
            '--json tagName -q \'.[0].tagName\''
      RR.mock(gh).run(cmd) { 'v1.2.3' }

      result = sut.latest_version

      expect(result).to eq('v1.2.3')
    end
  end

  describe '#releases' do
    it 'splits gh output into release tag array' do
      cmd = 'release list -R anthropics/claude-code --limit 3 ' \
            '--json tagName -q \'.[].tagName\''
      RR.mock(gh).run(cmd) { "v1.0.0\nv0.9.0\nv0.8.0" }

      result = sut.releases(3)

      expect(result).to eq(%w[v1.0.0 v0.9.0 v0.8.0])
    end

    it 'filters empty lines from gh output' do
      cmd = 'release list -R anthropics/claude-code --limit 3 ' \
            '--json tagName -q \'.[].tagName\''
      RR.mock(gh).run(cmd) { "v1.0.0\n\nv0.9.0\nv0.8.0" }

      result = sut.releases(3)

      expect(result).to eq(%w[v1.0.0 v0.9.0 v0.8.0])
    end

    it 'respects the limit parameter' do
      cmd = 'release list -R anthropics/claude-code --limit 5 ' \
            '--json tagName -q \'.[].tagName\''
      RR.mock(gh).run(cmd) { "v1.0.0\nv0.9.0\nv0.8.0\nv0.7.0\nv0.6.0" }

      result = sut.releases(5)

      expect(result).to eq(%w[v1.0.0 v0.9.0 v0.8.0 v0.7.0 v0.6.0])
    end
  end
end
