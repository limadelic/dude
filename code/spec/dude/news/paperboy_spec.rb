require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/paperboy'

describe Dude::News::Paperboy do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:gh) { Object.new }

  before { stub(Dude::Helpers::Gh).new { gh } }

  describe '#latest_version' do
    it 'returns the latest release tag' do
      stub(gh).run(/release list.*--limit 1/) { 'v1.2.3' }

      expect(sut.latest_version)
        .to eq('v1.2.3')
    end
  end

  describe '#releases' do
    it 'splits gh output into release tag array' do
      stub(gh).run(/release list.*--limit 3/) \
        { "v1.0.0\nv0.9.0\nv0.8.0" }

      expect(sut.releases(3))
        .to eq(%w[v1.0.0 v0.9.0 v0.8.0])
    end

    it 'filters empty lines from gh output' do
      stub(gh).run(/release list.*--limit 3/) \
        { "v1.0.0\n\nv0.9.0\nv0.8.0" }

      expect(sut.releases(3))
        .to eq(%w[v1.0.0 v0.9.0 v0.8.0])
    end

    it 'respects the limit parameter' do
      stub(gh).run(/release list.*--limit 5/) \
        { "v1.0.0\nv0.9.0\nv0.8.0\nv0.7.0\nv0.6.0" }

      expect(sut.releases(5))
        .to eq(%w[v1.0.0 v0.9.0 v0.8.0 v0.7.0 v0.6.0])
    end
  end
end
