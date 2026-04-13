require_relative '../../spec_helper'
require_relative '../../../lib/dude/news/news'

describe Dude::News::News do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:paperboy) { Object.new }
  let(:sommelier) { Object.new }

  before do
    stub(Dude::News::Paperboy).new { paperboy }
    stub(Dude::News::Sommelier).new { sommelier }
    ENV['CC_VERSION'] = '1.0.0'
  end

  after { ENV.delete('CC_VERSION') }

  describe '#fetch' do
    before do
      stub(paperboy).latest_version { '1.2.3' }
      stub(paperboy).releases(5) { %w[v1.0.0 v0.9.0 v0.8.0] }
      stub(sommelier).taste('1.2.3') \
        { { conclusion: 'success', url: nil, error: nil } }
    end

    it 'includes installed version in output' do
      expect(sut.fetch)
        .to include('Installed: 1.0.0, Latest: 1.2.3')
    end

    it 'includes vintage result in output' do
      expect(sut.fetch)
        .to include('Vintage 1.2.3: success')
    end

    it 'includes releases up to limit in output' do
      expect(sut.fetch)
        .to include('v1.0.0', 'v0.9.0')
    end
  end

  context 'with limit 1' do
    let(:sut) { described_class.new(limit: 1) }

    before do
      stub(paperboy).latest_version { '1.2.3' }
      stub(paperboy).releases(1) { %w[v1.0.0] }
      stub(sommelier).taste('1.2.3') \
        { { conclusion: 'success', url: nil, error: nil } }
    end

    it 'includes only requested releases in output' do
      expect(sut.fetch).to include('v1.0.0')
    end

    it 'excludes releases beyond limit' do
      expect(sut.fetch).not_to include('v0.9.0')
    end
  end

  describe '#fetch with missing CC_VERSION' do
    before do
      ENV.delete('CC_VERSION')
      stub(paperboy).latest_version { '1.0.0' }
      stub(paperboy).releases(5) { [] }
      stub(sommelier).taste('1.0.0') \
        { { conclusion: 'success', url: nil, error: nil } }
    end

    it 'defaults installed version to unknown' do
      expect(sut.fetch)
        .to include('Installed: unknown')
    end
  end
end
