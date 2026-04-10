require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/wait'

describe Dude::Helpers::Wait do
  include RR::DSL

  let(:sut) { described_class.new(interval: 0.01) }

  describe '#until' do
    it 'returns immediately when condition is true' do
      expect(sut.until { true }).to be true
    end

    it 'polls until condition becomes true' do
      calls = 0
      sut.until do
        calls += 1
        calls >= 3
      end
      expect(calls).to eq(3)
    end

    it 'raises on timeout' do
      sut_with_timeout = described_class.new(interval: 0.01, timeout: 0.03)
      expect {
        sut_with_timeout.until { false }
      }.to raise_error(Dude::Helpers::Wait::Timeout)
    end
  end
end
