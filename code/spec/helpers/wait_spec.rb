require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/wait'

describe Dude::Helpers::Wait do
  include RR::DSL

  let(:interval) { 0.01 }
  let(:timeout) { nil }
  let(:sut) { described_class.new(interval: interval, timeout: timeout) }

  before do
    stub(Kernel).sleep
  end

  describe '#until' do
    it 'returns immediately when condition is true' do
      sut.until { true }
    end

    context 'polling until condition becomes true' do
      before do
        mock(Kernel).sleep.times(2)
      end

      it 'calls sleep while polling' do
        calls = 0
        sut.until do
          calls += 1
          calls >= 3
        end
      end
    end

    context 'timeout exceeded' do
      let(:interval) { 0.001 }
      let(:timeout) { 0.001 }

      it 'raises on timeout' do
        expect {
          sut.until { false }
        }.to raise_error(Dude::Helpers::Wait::Timeout)
      end
    end
  end
end
