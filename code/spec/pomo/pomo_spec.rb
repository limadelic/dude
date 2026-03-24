require_relative '../spec_helper'
require_relative '../../lib/pomo/pomo'

describe Pomo::Timer do
  let(:future) { Time.now.to_i + 100 }
  let(:content) { "default|#{future}" }
  let(:fs) { instance_double(Helpers::FS, exist?: true, read: content) }
  let(:timer) { Pomo::Timer.new(fs) }

  def strip(s)
    s.gsub(/\e\[[0-9;]*m/, '')
  end

  describe '#render' do
    it 'returns nil when no file' do
      allow(fs).to receive(:exist?).and_return(false)
      expect(timer.render).to be_nil
    end

    it 'returns nil when expired' do
      allow(fs).to receive(:read).and_return("default|#{Time.now.to_i - 100}")
      expect(timer.render).to be_nil
    end

    it 'returns nil when transitioning' do
      allow(fs).to receive(:read).and_return("transitioning|#{future}")
      expect(timer.render).to be_nil
    end

    it 'renders active timer' do
      expect(timer.render).to include('🍅')
    end
  end

  describe 'types' do
    it 'tomato for default' do
      expect(timer.render).to include('🍅')
    end

    it 'apple for break' do
      allow(fs).to receive(:read).and_return("break|#{future}")
      expect(timer.render).to include('🍏')
    end

    it 'apple for long break' do
      allow(fs).to receive(:read).and_return("long break|#{future}")
      expect(timer.render).to include('🍏')
    end
  end

  describe 'colors' do
    it 'red for default' do
      expect(timer.render).to include("\e[31m")
    end

    it 'green for break' do
      allow(fs).to receive(:read).and_return("break|#{future}")
      expect(timer.render).to include("\e[32m")
    end
  end

  describe 'progress' do
    it 'empty bar at start' do
      allow(fs).to receive(:read).and_return("default|#{Time.now.to_i + 1500}")
      expect(strip(timer.render)).to match(/░{9}/)
    end

    it 'filled bar near end' do
      allow(fs).to receive(:read).and_return("default|#{Time.now.to_i + 10}")
      expect(strip(timer.render)).to match(/█+/)
    end
  end
end
