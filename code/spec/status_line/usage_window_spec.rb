require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/usage_window'

describe Dude::StatusLine::UsageWindow do
  include RR::DSL

  let(:resets_at_time) { 1000000 }
  let(:window_len) { 5 * 3600 }
  let(:now) { 900000 }

  let(:window_entry) { { 'resets_at' => resets_at_time } }
  let(:sut) do
    described_class.new(window_entry, window_len: window_len, now: now)
  end

  describe '#range' do
    it 'returns [start_time, now]' do
      start_time = resets_at_time - window_len
      expect(sut.range).to eq([start_time, now])
    end

    context 'when window_entry is nil' do
      let(:window_entry) { nil }

      it 'returns nil' do
        expect(sut.range).to be_nil
      end
    end

    context 'when resets_at is absent' do
      let(:window_entry) { {} }

      it 'returns nil' do
        expect(sut.range).to be_nil
      end
    end

    context 'when resets_at is nil' do
      let(:window_entry) { { 'resets_at' => nil } }

      it 'returns nil' do
        expect(sut.range).to be_nil
      end
    end

    context 'when now is not injected' do
      let(:sut) do
        described_class.new(window_entry, window_len: window_len)
      end

      before { stub(Time).now { Time.at(1234567890) } }

      it 'uses current time' do
        start_time = resets_at_time - window_len
        expect(sut.range).to eq([start_time, 1234567890])
      end
    end

    context 'with 7-day window' do
      let(:window_len) { 7 * 24 * 3600 }

      it 'applies correct window length' do
        start_time = resets_at_time - window_len
        expect(sut.range).to eq([start_time, now])
      end
    end
  end
end
