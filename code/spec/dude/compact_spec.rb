require_relative '../spec_helper'
require_relative '../../lib/dude/compact'

describe Dude::Compact do
  include RR::DSL

  let(:sut) { described_class.new(riley, asks) }
  let(:riley) { 'riley: ship the parser' }
  let(:asks) { [later, earlier] }
  let(:earlier) { ask(early_time, 'ship the parser on Monday') }
  let(:later) { ask(late_time, 'prepare the demo') }
  let(:early_time) { Time.utc(2026, 11, 18, 14, 3) }
  let(:late_time) { Time.utc(2026, 11, 18, 23, 50) }
  let(:zone) { 'IST-5:30' }
  let(:cap) { 10_000 }
  let(:half_cap) { cap / 2 }
  let(:over_cap) { cap * 2 }
  let(:tenth_cap) { cap / 10 }
  let(:three_tenths_cap) { tenth_cap * 3 }
  let(:utf16_bytes_per_unit) { 2 }
  let(:head) { 2 }
  let(:last_index) { -1 }
  let(:header) { described_class::HEADER }

  around do |example|
    saved = ENV.fetch('TZ', nil)
    ENV['TZ'] = zone
    example.run
  ensure
    ENV['TZ'] = saved
  end

  def ask(time, text)
    fake_ask = Object.new
    stub(fake_ask).time { time }
    stub(fake_ask).text { text }
    fake_ask
  end

  def units(text)
    text.encode('UTF-16LE').bytesize / utf16_bytes_per_unit
  end

  def units_with(*rows)
    units([riley, header, *rows].join("\n"))
  end

  def filler(word, size)
    word * (size / word.length)
  end

  describe '#call' do
    let(:rows) do
      [
        riley, described_class::HEADER,
        'Nov 18 7:33 PM ship the parser on Monday',
        'Nov 19 5:20 AM prepare the demo'
      ]
    end

    it 'puts riley, header, then asks oldest first' do
      expect(sut.call).to eq(rows)
    end

    context 'when there is no riley line' do
      let(:riley) { nil }

      it 'starts with the header' do
        expect(sut.call.first).to eq(described_class::HEADER)
      end
    end

    context 'when there are no asks' do
      let(:asks) { [] }

      it 'keeps riley and header' do
        expect(sut.call).to eq([riley, described_class::HEADER])
      end
    end

    context 'when the asks pass the cap' do
      let(:new_words) { filler('frumble ', half_cap) }
      let(:old_ask) { ask(early_time, filler('blorp ', over_cap)) }
      let(:new_ask) { ask(late_time, new_words) }
      let(:asks) { [old_ask, new_ask] }

      it 'drops the oldest ask whole' do
        expect(sut.call).to eq(
          [riley, described_class::HEADER, "Nov 19 5:20 AM #{new_words}"]
        )
      end
    end

    context 'when the oldest ask fits alone but not with the newest' do
      let(:old_text) { filler('blorp ', three_tenths_cap) }
      let(:new_text) { filler('frumble ', cap - tenth_cap) }
      let(:asks) { [ask(early_time, old_text), ask(late_time, new_text)] }

      it 'keeps only the newest ask' do
        expect(sut.call).to eq(
          [riley, described_class::HEADER, "Nov 19 5:20 AM #{new_text}"]
        )
      end
    end

    context 'when the newest ask alone passes the cap' do
      let(:huge) { ask(late_time, filler('blorp ', over_cap)) }
      let(:asks) { [huge] }

      it 'keeps riley and header first' do
        expect(sut.call.first(head)).to eq([riley, described_class::HEADER])
      end

      it 'cuts the ask to fit the cap' do
        expect(units(sut.call.join("\n"))).to eq(cap)
      end
    end

    context 'when riley and header alone pass the cap' do
      let(:riley) { "riley: #{filler('ship ', over_cap)}" }

      it 'keeps riley and header' do
        expect(sut.call).to eq([riley, described_class::HEADER])
      end
    end

    context 'when the newest ask is emoji past the cap' do
      let(:emoji) { ask(late_time, '🐳' * cap) }
      let(:asks) { [emoji] }

      it 'counts the emoji as two units' do
        expect(units(sut.call.join("\n"))).to be <= cap
      end

      it 'cuts after a whole emoji' do
        expect(sut.call.last[last_index]).to eq('🐳')
      end
    end

    context 'when the emoji is under the cap in chars but over in utf-16' do
      let(:emoji_count) { half_cap + tenth_cap }
      let(:asks) { [ask(late_time, '🐳' * emoji_count)] }

      it 'keeps the output within the cap in utf-16 units' do
        expect(units(sut.call.join("\n"))).to be <= cap
      end
    end

    context 'when the riley line holds emoji' do
      let(:emoji_count) { 100 }
      let(:riley) { "riley: #{'🐳' * emoji_count}" }
      let(:older_row) { 'Nov 18 7:33 PM older' }
      let(:newer_prefix) { 'Nov 19 5:20 AM ' }
      let(:newer_text) { 'x' * (cap - units_with(newer_prefix)) }
      let(:asks) { [ask(early_time, 'older'), ask(late_time, newer_text)] }

      it 'keeps the output within the cap in utf-16 units' do
        expect(units(sut.call.join("\n"))).to be <= cap
      end
    end

    context 'when the asks total exactly the cap' do
      let(:fill_char) { 'x' }
      let(:older_text) { 'x' * tenth_cap }
      let(:older_row) { "Nov 18 7:33 PM #{older_text}" }
      let(:newer_prefix) { 'Nov 19 5:20 AM ' }
      let(:fit_text) { fill_char * (cap - units_with(older_row, newer_prefix)) }
      let(:newer_text) { fit_text }
      let(:newer_row) { "#{newer_prefix}#{newer_text}" }
      let(:asks) { [ask(early_time, older_text), ask(late_time, newer_text)] }
      let(:all_rows) { [riley, header, older_row, newer_row] }

      it 'keeps every ask' do
        expect(sut.call).to eq(all_rows)
      end

      context 'when the newest ask is one unit longer' do
        let(:newer_text) { "#{fit_text}#{fill_char}" }

        it 'drops the oldest ask whole' do
          expect(sut.call).to eq([riley, header, newer_row])
        end
      end

      context 'when the fit is made of U+FFFF' do
        let(:fill_char) { "￿" }

        it 'keeps every ask' do
          expect(sut.call).to eq(all_rows)
        end
      end
    end

    context 'when an ask is at noon or midnight' do
      let(:noon_time) { Time.utc(2026, 11, 18, 6, 30) }
      let(:midnight_time) { Time.utc(2026, 11, 18, 18, 30) }
      let(:noon) { ask(noon_time, 'lunch') }
      let(:midnight) { ask(midnight_time, 'sleep') }
      let(:asks) { [midnight, noon] }

      let(:rows) do
        [
          riley, described_class::HEADER,
          'Nov 18 12:00 PM lunch',
          'Nov 19 12:00 AM sleep'
        ]
      end

      it 'shows twelve as the hour for both' do
        expect(sut.call).to eq(rows)
      end
    end
  end
end
