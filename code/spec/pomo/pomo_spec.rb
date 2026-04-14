require_relative '../spec_helper'
require_relative '../../lib/dude/pomo/pomo'

describe Dude::Pomo::Pomo do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:future) { Time.now.to_i + 100 }
  let(:content) { "default|#{future}" }

  before do
    stub(File).exist? { true }
    stub(File).read { content }
  end

  def strip(s)
    s.gsub(/\e\[[0-9;]*m/, '')
  end

  describe '#to_s' do
    it 'returns nil when no file' do
      stub(File).exist? { false }

      expect(sut.to_s).to be_nil
    end

    it 'returns nil when expired' do
      stub(File).read { "default|#{Time.now.to_i - 100}" }

      expect(sut.to_s).to be_nil
    end

    it 'returns nil when transitioning' do
      stub(File).read { "transitioning|#{future}" }

      expect(sut.to_s).to be_nil
    end

    it 'renders active default timer with tomato' do
      stub(File).read { "default|#{Time.now.to_i + 1500}" }

      expect(sut.to_s).to include('🍅')
    end

    it 'renders active default timer with red color' do
      stub(File).read { "default|#{Time.now.to_i + 1500}" }

      expect(sut.to_s).to include("\e[31m")
    end

    it 'renders active default timer with progress bar' do
      stub(File).read { "default|#{Time.now.to_i + 1500}" }

      expect(strip(sut.to_s)).to match(/░{9}/)
    end

    it 'renders active break timer with apple' do
      stub(File).read { "break|#{future}" }

      expect(sut.to_s).to include('🍏')
    end

    it 'renders active break timer with green color' do
      stub(File).read { "break|#{future}" }

      expect(sut.to_s).to include("\e[32m")
    end

    it 'renders long break with apple' do
      stub(File).read { "long break|#{future}" }

      expect(sut.to_s).to include('🍏')
    end

    it 'renders long break with green color' do
      stub(File).read { "long break|#{future}" }

      expect(sut.to_s).to include("\e[32m")
    end

    it 'shows progress near completion' do
      stub(File).read { "default|#{Time.now.to_i + 10}" }

      expect(strip(sut.to_s)).to match(/█+/)
    end

    it 'renders unknown timer type' do
      stub(File).read { "unknown|#{future}" }

      expect(sut.to_s).not_to be_nil
    end
  end
end
