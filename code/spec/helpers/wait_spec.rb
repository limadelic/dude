require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/wait'

describe Dude::Helpers::Wait do
  describe '#until' do
    it 'returns immediately when condition is true' do
      result = described_class.new(interval: 0.01).until { true }
      expect(result).to be true
    end

    it 'polls until condition becomes true' do
      calls = 0
      described_class.new(interval: 0.01).until do
        calls += 1
        calls >= 3
      end
      expect(calls).to eq(3)
    end

    it 'raises on timeout' do
      expect {
        described_class.new(interval: 0.01, timeout: 0.03).until { false }
      }.to raise_error(Dude::Helpers::Wait::Timeout)
    end
  end
end
