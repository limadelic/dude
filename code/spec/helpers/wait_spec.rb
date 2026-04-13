require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/wait'

describe Dude::Helpers::Wait do
  include RR::DSL

  before do
    stub(Kernel).sleep
  end

  describe '#until' do
    it 'returns immediately when condition is true' do
      sut = described_class.new(interval: 0.01)
      sut.until { true }
    end

    it 'polls until condition becomes true' do
      mock(Kernel).sleep.times(2)
      sut = described_class.new(interval: 0.01)

      calls = 0
      sut.until do
        calls += 1
        calls >= 3
      end
    end

    it 'raises on timeout' do
      sut = described_class.new(interval: 0.001, timeout: 0.001)
      expect {
        sut.until { false }
      }.to raise_error(Dude::Helpers::Wait::Timeout)
    end
  end
end
