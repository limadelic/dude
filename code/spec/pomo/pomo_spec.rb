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

    it 'renders active timer' do
      stub(File).read { content }

      expect(sut.to_s).to include('🍅')
    end
  end

  describe 'types' do
    it 'tomato for default' do
      stub(File).read { content }

      expect(sut.to_s).to include('🍅')
    end

    it 'apple for break' do
      stub(File).read { "break|#{future}" }

      expect(sut.to_s).to include('🍏')
    end

    it 'apple for long break' do
      stub(File).read { "long break|#{future}" }

      expect(sut.to_s).to include('🍏')
    end
  end

  describe 'colors' do
    it 'red for default' do
      stub(File).read { content }

      expect(sut.to_s).to include("\e[31m")
    end

    it 'green for break' do
      stub(File).read { "break|#{future}" }

      expect(sut.to_s).to include("\e[32m")
    end
  end

  describe 'progress' do
    it 'empty bar at start' do
      future_end = Time.now.to_i + 1500
      stub(File).read { "default|#{future_end}" }

      expect(strip(sut.to_s)).to match(/░{9}/)
    end

    it 'filled bar near end' do
      stub(File).read { "default|#{Time.now.to_i + 10}" }

      expect(strip(sut.to_s)).to match(/█+/)
    end
  end
end
