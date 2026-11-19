require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/band'

describe Dude::Transcript::Band do
  let(:sut) { described_class.new(ratio, active_count) }

  context 'when ratio is 1.9' do
    let(:ratio) { 1.9 }
    let(:active_count) { 2 }

    it 'returns nil' do
      expect(sut.color).to be_nil
    end
  end

  context 'when ratio is 2.0' do
    let(:ratio) { 2.0 }
    let(:active_count) { 2 }

    it 'returns yellow' do
      expect(sut.color).to eq(:yellow)
    end
  end

  context 'when ratio is 2.99' do
    let(:ratio) { 2.99 }
    let(:active_count) { 2 }

    it 'returns yellow' do
      expect(sut.color).to eq(:yellow)
    end
  end

  context 'when ratio is 3.0' do
    let(:ratio) { 3.0 }
    let(:active_count) { 2 }

    it 'returns red' do
      expect(sut.color).to eq(:red)
    end
  end

  context 'when ratio is nil' do
    let(:ratio) { nil }
    let(:active_count) { 2 }

    it 'returns nil' do
      expect(sut.color).to be_nil
    end
  end

  context 'when solo (active_count is 1)' do
    let(:ratio) { 5.0 }
    let(:active_count) { 1 }

    it 'returns nil' do
      expect(sut.color).to be_nil
    end
  end
end
