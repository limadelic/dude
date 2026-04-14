require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/spend'
require_relative '../examples/shared'

describe Dude::StatusLine::Spend do
  include RR::DSL
  include_context 'StatusLine helpers'

  let(:sut) { described_class.new(activity_data) }
  let(:activity_data) { mock_activity(spend: spend_amount) }
  let(:spend_amount) { 0 }

  describe 'Spend section color coding' do
    describe 'at 0%' do
      it 'is green' do
        expect(sut.to_s).to include("\e[32m💰")
      end

      it 'shows empty bars' do
        expect(sut.to_s).to include("░░░░░░░░░")
      end
    end

    describe 'at 20%' do
      let(:spend_amount) { Dude::StatusLine::Spend::SPEND_CAP * 20 / 100.0 }

      it 'is green' do
        expect(sut.to_s).to include("\e[32m💰")
      end

      it 'shows some bars filled' do
        expect(sut.to_s).to include("█")
      end
    end

    describe 'at 33% boundary' do
      let(:spend_amount) { Dude::StatusLine::Spend::SPEND_CAP * 33 / 100.0 }

      it 'is yellow' do
        expect(sut.to_s).to include("\e[38;5;226m💰")
      end
    end

    describe 'at 50%' do
      let(:spend_amount) { Dude::StatusLine::Spend::SPEND_CAP * 50 / 100.0 }

      it 'is yellow' do
        expect(sut.to_s).to include("\e[38;5;226m💰")
      end
    end

    describe 'at 66% boundary' do
      let(:spend_amount) { Dude::StatusLine::Spend::SPEND_CAP * 66 / 100.0 }

      it 'is yellow' do
        expect(sut.to_s).to include("\e[38;5;226m💰")
      end
    end

    describe 'at 67% boundary' do
      let(:spend_amount) { Dude::StatusLine::Spend::SPEND_CAP * 67 / 100.0 }

      it 'is red' do
        expect(sut.to_s).to include("\e[31m💰")
      end
    end

    describe 'at 80%' do
      let(:spend_amount) { Dude::StatusLine::Spend::SPEND_CAP * 80 / 100.0 }

      it 'is red' do
        expect(sut.to_s).to include("\e[31m💰")
      end

      it 'shows mostly filled bars' do
        expect(sut.to_s).to include("███████")
      end
    end

    describe 'over 100%' do
      let(:spend_amount) { Dude::StatusLine::Spend::SPEND_CAP * 150 / 100.0 }

      it 'is red' do
        expect(sut.to_s).to include("\e[31m💰")
      end

      it 'caps at 100% for bar display' do
        expect(sut.to_s).to include("█████████")
      end
    end
  end
end
