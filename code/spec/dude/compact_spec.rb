require_relative '../spec_helper'
require_relative '../../lib/dude/compact'

describe Dude::Compact do
  include RR::DSL

  let(:sut) { described_class.new(riley, asks) }
  let(:riley) { 'riley: ship the parser' }
  let(:asks) { [later, earlier] }
  let(:earlier) { Object.new }
  let(:later) { Object.new }
  let(:zone) { 'IST-5:30' }

  around do |example|
    saved = ENV.fetch('TZ', nil)
    ENV['TZ'] = zone
    example.run
  ensure
    ENV['TZ'] = saved
  end

  before do
    stub(earlier).time { Time.utc(2026, 11, 18, 14, 3) }
    stub(earlier).text { 'ship the parser on Monday' }
    stub(later).time { Time.utc(2026, 11, 18, 23, 50) }
    stub(later).text { 'prepare the demo' }
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

    context 'when an ask is at noon or midnight' do
      let(:noon) { Object.new }
      let(:midnight) { Object.new }
      let(:asks) { [midnight, noon] }

      let(:rows) do
        [
          riley, described_class::HEADER,
          'Nov 18 12:00 PM lunch',
          'Nov 19 12:00 AM sleep'
        ]
      end

      before do
        stub(noon).time { Time.utc(2026, 11, 18, 6, 30) }
        stub(noon).text { 'lunch' }
        stub(midnight).time { Time.utc(2026, 11, 18, 18, 30) }
        stub(midnight).text { 'sleep' }
      end

      it 'shows twelve as the hour for both' do
        expect(sut.call).to eq(rows)
      end
    end
  end
end
