require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/rate_limit'

describe Dude::StatusLine::RateLimit do
  include RR::DSL

  before { stub_const('Dude::StatusLine::Format::JETBRAINS', false) }
  before { stub(Time).now { Time.at(now_time) } }

  let(:now_time) { 1781500000 }

  describe '#to_s' do
    describe 'fill percentage' do
      subject {
        described_class.new(
          used_pct: used_pct, resets_at: resets_at_time,
          window_len: window_len, emoji: '☀️'
        ).to_s
      }

      let(:bar) { Dude::StatusLine::Format.strip(subject)[/☀️ ([█░]+)/, 1] }
      let(:used_pct) { 0 }

      let(:resets_at_time) { now_time + 3600 }
      let(:window_len) { 3600 }

      context 'at 0% used' do
        it 'shows 0 filled blocks' do
          expect(bar.count("█")).to eq(0)
        end
      end

      context 'at 3% used (small nonzero)' do
        let(:used_pct) { 3 }

        it 'shows at least 1 filled block' do
          expect(bar.count("█")).to be >= 1
        end
      end

      context 'at 50% used' do
        let(:used_pct) { 50 }

        it 'shows 4-5 filled blocks' do
          expect(bar.count("█")).to be_between(4, 5)
        end
      end

      context 'at 100% used' do
        let(:used_pct) { 100 }

        it 'shows 9 filled blocks' do
          expect(bar.count("█")).to eq(9)
        end
      end
    end

    describe 'color by burn rate' do
      def output_at_ratio(used_pct, elapsed_pct, window_len)
        elapsed_time = elapsed_pct * window_len / 100.0
        resets_at = now_time + window_len - elapsed_time
        described_class.new(
          used_pct: used_pct,
          resets_at: resets_at.to_i,
          window_len: window_len,
          emoji: '☀️'
        ).to_s
      end

      context 'at ratio 0.5 (GREEN: used_pct / elapsed_pct <= 1.0)' do
        it 'is green' do
          output = output_at_ratio(10, 50, 3600)
          expect(output).to include("\e[32m")
        end
      end

      context 'at ratio 1.0 (GREEN: boundary)' do
        it 'is green' do
          output = output_at_ratio(50, 50, 3600)
          expect(output).to include("\e[32m")
        end
      end

      context 'at ratio 1.5 (YELLOW: 1.0 < ratio <= 2.0)' do
        it 'is yellow' do
          output = output_at_ratio(30, 20, 3600)
          expect(output).to include("\e[38;5;226m")
        end
      end

      context 'at ratio 2.0 (YELLOW: boundary)' do
        it 'is yellow' do
          output = output_at_ratio(40, 20, 3600)
          expect(output).to include("\e[38;5;226m")
        end
      end

      context 'at ratio 3.0 (RED: ratio > 2.0)' do
        it 'is red' do
          output = output_at_ratio(60, 20, 3600)
          expect(output).to include("\e[31m")
        end
      end

      context 'when no elapsed time (ratio handling)' do
        it 'treats zero elapsed as ratio 0 (GREEN)' do
          resets_at = now_time + 3600
          output = described_class.new(
            used_pct: 50,
            resets_at: resets_at,
            window_len: 3600,
            emoji: '☀️'
          ).to_s
          expect(output).to include("\e[32m")
        end
      end
    end

    describe 'emoji rendering' do
      it 'includes the emoji' do
        output = described_class.new(
          used_pct: 25,
          resets_at: now_time + 3600,
          window_len: 3600,
          emoji: '☀️'
        ).to_s
        expect(output).to include('☀️')
      end

      it 'works with moon emoji for 7-day' do
        output = described_class.new(
          used_pct: 25,
          resets_at: now_time + 604800,
          window_len: 604800,
          emoji: '🌙'
        ).to_s
        expect(output).to include('🌙')
      end
    end
  end
end
