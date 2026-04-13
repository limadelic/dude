require_relative '../spec_helper'
require_relative '../../lib/dude/pomo/pomo'

describe Dude::Pomo::Pomo do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:future) { Time.now.to_i + 100 }
  let(:content) { "default|#{future}" }

  before do
    stub(File).exist? { true }
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

    it 'renders active default timer with tomato and progress bar' do
      future_end = Time.now.to_i + 1500
      stub(File).read { "default|#{future_end}" }

      result = sut.to_s
      expect(result).to include('🍅')
      expect(result).to include("\e[31m")
      expect(strip(result)).to match(/░{9}/)
    end

    it 'renders active break timer with apple and progress bar' do
      stub(File).read { "break|#{future}" }

      result = sut.to_s
      expect(result).to include('🍏')
      expect(result).to include("\e[32m")
    end

    it 'renders long break same as break' do
      stub(File).read { "long break|#{future}" }

      result = sut.to_s
      expect(result).to include('🍏')
      expect(result).to include("\e[32m")
    end

    it 'shows progress near completion' do
      stub(File).read { "default|#{Time.now.to_i + 10}" }

      expect(strip(sut.to_s)).to match(/█+/)
    end

    it 'returns nil for unknown timer type' do
      stub(File).read { "unknown|#{future}" }

      expect(sut.to_s).not_to be_nil
    end
  end
end
