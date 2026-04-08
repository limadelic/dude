require_relative '../spec_helper'
require_relative '../../lib/dude/pomo/pomo'

describe Dude::Pomo::Pomo do
  let(:future) { Time.now.to_i + 100 }
  let(:timer) { Dude::Pomo::Pomo.new }

  def strip(s)
    s.gsub(/\e\[[0-9;]*m/, '')
  end

  before do
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:read).and_return("default|#{future}")
  end

  describe '#to_s' do
    it 'returns nil when no file' do
      allow(File).to receive(:exist?).and_return(false)
      expect(timer.to_s).to be_nil
    end

    it 'returns nil when expired' do
      allow(File).to receive(:read).and_return("default|#{Time.now.to_i - 100}")
      expect(timer.to_s).to be_nil
    end

    it 'returns nil when transitioning' do
      allow(File).to receive(:read).and_return("transitioning|#{future}")
      expect(timer.to_s).to be_nil
    end

    it 'renders active timer' do
      expect(timer.to_s).to include('🍅')
    end
  end

  describe 'types' do
    it 'tomato for default' do
      expect(timer.to_s).to include('🍅')
    end

    it 'apple for break' do
      allow(File).to receive(:read).and_return("break|#{future}")
      expect(timer.to_s).to include('🍏')
    end

    it 'apple for long break' do
      allow(File).to receive(:read).and_return("long break|#{future}")
      expect(timer.to_s).to include('🍏')
    end
  end

  describe 'colors' do
    it 'red for default' do
      expect(timer.to_s).to include("\e[31m")
    end

    it 'green for break' do
      allow(File).to receive(:read).and_return("break|#{future}")
      expect(timer.to_s).to include("\e[32m")
    end
  end

  describe 'progress' do
    it 'empty bar at start' do
      future = Time.now.to_i + 1500
      allow(File).to receive(:read).and_return("default|#{future}")
      expect(strip(timer.to_s)).to match(/░{9}/)
    end

    it 'filled bar near end' do
      allow(File).to receive(:read).and_return("default|#{Time.now.to_i + 10}")
      expect(strip(timer.to_s)).to match(/█+/)
    end
  end
end
