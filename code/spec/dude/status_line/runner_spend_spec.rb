require_relative '../../spec_helper'
require_relative '../../../lib/dude/status_line/runner'

describe 'Runner spend_section integration' do
  include RR::DSL
  let(:session_input) { '{}' }
  let(:spend_instance) { Object.new }
  let(:token_fetcher_spy) { Object.new }
  let(:client_spy) { Object.new }
  let(:cache_spy) { Object.new }
  let(:dudes_instance) { Object.new }

  before do
    stub(Dude::StatusLine::AnthropicToken).fetch { 'test_token' }
    stub(Dude::StatusLine::AnthropicSpendClient).new(anything) { client_spy }
    stub(Dude::StatusLine::SpendCache).new { cache_spy }
    stub(Dude::StatusLine::Spend).new(anything, anything, anything) { spend_instance }
    stub(spend_instance).to_s { '💰 ████░░░░░ 45%' }
    stub(Dude::StatusLine::Dudes).new(anything, anything, anything, anything) { dudes_instance }
    stub(dudes_instance).write_status { nil }
    stub(dudes_instance).to_s { '' }
    stub(Dude::Pomo::Pomo).new { Object.new }
    stub(Dude::StatusLine::Models).new(anything, anything) { Object.new }
  end

  describe '#spend_section' do
    it 'builds status line with spend section' do
      sut = Dude::StatusLine::Runner.new(session_input)
      output = capture_output { sut.run }

      expect(output).to include('💰 ████░░░░░ 45%')
    end
  end
end
