require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/wait'

describe Dude::Helpers::Wait do
  include RR::DSL

  describe '#until' do
    it 'returns immediately when condition is true' do
      sut = described_class.new(interval: 0.01)
      mock(sut).sleep.times(0)
      sut.until { true }
    end

    it 'polls until condition becomes true' do
      sut = described_class.new(interval: 0.01)
      mock(sut).sleep.times(2)

      calls = 0
      sut.until do
        calls += 1
        calls >= 3
      end
    end

    it 'raises on timeout' do
      current_time = 0
      mock(Time).now.times(any_times) { Time.at(current_time) }
      mock(Kernel).sleep { |interval| current_time += interval }

      sut = described_class.new(interval: 0.01, timeout: 0.03)
      expect {
        sut.until { false }
      }.to raise_error(Dude::Helpers::Wait::Timeout)
    end
  end
end
