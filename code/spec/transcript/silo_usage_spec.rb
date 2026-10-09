require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/silo_usage'

describe Dude::Transcript::SiloUsage do
  include RR::DSL

  let(:cache) do
    double.tap do |d|
      stub(d).cost(window, 'session_a') { 6 }
      stub(d).cost(window, 'session_b') { 2 }
      stub(d).cost(window, 'session_c') { 1 }
      stub(d).cost(window, 'session_other') { 5 }
    end
  end

  let(:sessions_to_silos) do
    {
      'session_a' => 'silo_a',
      'session_b' => 'silo_b',
      'session_c' => 'silo_c',
      'session_other' => nil
    }
  end

  let(:window) { '5h' }

  let(:sut) { described_class.new(cache, sessions_to_silos, window) }

  describe '#cost' do
    it 'returns cost for a silo' do
      expect(sut.cost('silo_a')).to eq(6)
    end

    it 'sums costs for multiple sessions in same silo' do
      stub(cache).cost(window, 'session_a2') { 3 }
      sessions_to_silos['session_a2'] = 'silo_a'

      sut_new = described_class.new(cache, sessions_to_silos, window)
      expect(sut_new.cost('silo_a')).to eq(9)
    end

    it 'returns 0 for unknown silo' do
      expect(sut.cost('unknown')).to eq(0)
    end

    it 'returns cost for nil (other) sessions' do
      expect(sut.cost(nil)).to eq(5)
    end
  end

  describe '#total_cost' do
    it 'returns sum of all session costs' do
      expect(sut.total_cost).to eq(14)
    end
  end

  describe '#active_count' do
    it 'returns count of silos with cost > 0, excluding nil' do
      expect(sut.active_count).to eq(3)
    end

    context 'when only one silo is active' do
      let(:sessions_to_silos) do
        { 'session_a' => 'silo_a' }
      end

      let(:cache) do
        double.tap do |d|
          stub(d).cost(window, 'session_a') { 6 }
        end
      end

      it 'returns 1' do
        expect(sut.active_count).to eq(1)
      end
    end

    context 'when no silos have spend' do
      let(:sessions_to_silos) do
        { 'session_a' => 'silo_a' }
      end

      let(:cache) do
        double.tap do |d|
          stub(d).cost(window, 'session_a') { 0 }
        end
      end

      it 'returns 0' do
        expect(sut.active_count).to eq(0)
      end
    end
  end

  describe '#ratio' do
    it 'returns silo cost divided by average active cost' do
      expect(sut.ratio('silo_a')).to eq(2.0)
    end

    it 'calculates ratio as 1.0 for average-cost silo' do
      expect(sut.ratio('silo_b')).to be_within(0.001).of(0.667)
    end

    it 'returns nil when silo_id is nil' do
      expect(sut.ratio(nil)).to be_nil
    end

    context 'when active_count is 0' do
      let(:sessions_to_silos) do
        { 'session_a' => 'silo_a' }
      end

      let(:cache) do
        double.tap do |d|
          stub(d).cost(window, 'session_a') { 0 }
        end
      end

      it 'returns nil' do
        expect(sut.ratio('silo_a')).to be_nil
      end
    end

    context 'when only one silo is active' do
      let(:sessions_to_silos) do
        { 'session_a' => 'silo_a' }
      end

      let(:cache) do
        double.tap do |d|
          stub(d).cost(window, 'session_a') { 6 }
        end
      end

      it 'returns 1.0 (silo equals average)' do
        expect(sut.ratio('silo_a')).to eq(1.0)
      end
    end

    it 'returns nil for unknown silo' do
      expect(sut.ratio('unknown')).to be_nil
    end
  end
end
