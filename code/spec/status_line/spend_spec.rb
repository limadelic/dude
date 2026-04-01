require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/spend'
require_relative '../examples/shared'

describe Dude::StatusLine::Spend do
  include_context 'StatusLine helpers'

  before do
    allow(Dude::StatusLine::Dudes).to receive(:new).and_return(
      instance_double(
        Dude::StatusLine::Dudes, to_s: nil, write_status: nil
      )
    )
  end

  describe 'Spend section color coding' do
    it 'is green at 20%' do
      expect(output_for_spend_pct(20)).to include("\e[32m💰")
    end

    it 'is yellow at 50%' do
      expect(output_for_spend_pct(50)).to include("\e[38;5;226m💰")
    end

    it 'is red at 80%' do
      expect(output_for_spend_pct(80)).to include("\e[31m💰")
    end
  end

  private

  def output_for_spend_pct(pct)
    spend = Dude::StatusLine::Spend::SPEND_CAP * pct / 100.0
    activity_data = mock_activity(spend: spend)
    out(session, activity_data)
  end
end
