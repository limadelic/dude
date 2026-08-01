require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/paperboy'

describe Dude::News::Paperboy do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:gh) { Object.new }

  before do
    stub(Dude::Helpers::Gh).new { gh }
    stub(gh).run(/release list.*--limit 3/) { "v1.0.0\nv0.9.0\nv0.8.0" }
    stub(gh).run(/release view v1.0.0/) { "Release v1.0.0 body" }
    stub(gh).run(/release view v0.9.0/) { "Release v0.9.0 body" }
    stub(gh).run(/release view v0.8.0/) { "Release v0.8.0 body" }
  end

  describe '#latest_version' do
    it 'returns the latest release tag' do
      stub(gh).run(/release list.*--limit 1/) { 'v1.2.3' }
      expect(sut.latest_version).to eq('v1.2.3')
    end
  end

  describe '#release_body' do
    it 'returns body text for a release tag' do
      expect(sut.release_body('v1.0.0')).to eq('Release v1.0.0 body')
    end
  end

  describe '#releases' do
    it 'returns array of hashes with tag and body' do
      result = sut.releases(3)
      expect(result).to eq(
        [
          { tag: 'v1.0.0', body: 'Release v1.0.0 body' },
          { tag: 'v0.9.0', body: 'Release v0.9.0 body' },
          { tag: 'v0.8.0', body: 'Release v0.8.0 body' }
        ]
      )
    end

    it 'filters empty lines from gh output' do
      stub(gh).run(/release list.*--limit 3/) { "v1.0.0\n\nv0.9.0\nv0.8.0" }
      result = sut.releases(3)
      expect(result).to eq(
        [
          { tag: 'v1.0.0', body: 'Release v1.0.0 body' },
          { tag: 'v0.9.0', body: 'Release v0.9.0 body' },
          { tag: 'v0.8.0', body: 'Release v0.8.0 body' }
        ]
      )
    end

    it 'respects the limit parameter' do
      stub(gh).run(/release list.*--limit 5/) {
        "v1.0.0\nv0.9.0\nv0.8.0\nv0.7.0\nv0.6.0"
      }
      stub(gh).run(/release view v0.7.0/) { "Release v0.7.0 body" }
      stub(gh).run(/release view v0.6.0/) { "Release v0.6.0 body" }
      result = sut.releases(5)
      expect(result).to eq(
        [
          { tag: 'v1.0.0', body: 'Release v1.0.0 body' },
          { tag: 'v0.9.0', body: 'Release v0.9.0 body' },
          { tag: 'v0.8.0', body: 'Release v0.8.0 body' },
          { tag: 'v0.7.0', body: 'Release v0.7.0 body' },
          { tag: 'v0.6.0', body: 'Release v0.6.0 body' }
        ]
      )
    end
  end
end
