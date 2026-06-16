require_relative '../../spec_helper'
require_relative '../../../lib/dude/status_line/runner'

describe 'Runner spend_section integration' do
  include RR::DSL
  let(:dudes_instance) { Object.new }

  let(:models_instance) { Object.new }

  before do
    stub(Dude::StatusLine::Dudes).new(anything, anything, anything, anything) { dudes_instance }
    stub(dudes_instance).write_status { nil }
    stub(dudes_instance).to_s { '' }
    stub(Dude::Pomo::Pomo).new { Object.new }
    stub(Dude::StatusLine::Models).new(anything, anything) { models_instance }
    stub(models_instance).to_s { '' }
  end

  describe 'Pro account (with rate_limits)' do
    let(:session_input) do
      JSON.generate({
        'rate_limits' => {
          'five_hour' => { 'used_percentage' => 25, 'resets_at' => 1000000 },
          'seven_day' => { 'used_percentage' => 15, 'resets_at' => 2000000 }
        }
      })
    end

    it 'shows rate limit bars, not enterprise spend' do
      stub(Dude::StatusLine::EnterpriseSpend).new(anything, anything) { raise "should not call" }
      sut = Dude::StatusLine::Runner.new(session_input)
      output = capture_output { sut.run }

      expect(output).to include('☀️')
      expect(output).to include('🌙')
    end
  end

  describe 'Enterprise account (no rate_limits) with valid token' do
    let(:session_input) { '{}' }
    let(:enterprise_spend_instance) { Object.new }
    let(:spend_cache_instance) { Object.new }
    let(:checkpoint_instance) { Object.new }

    before do
      mock(Dude::StatusLine::AnthropicToken).fetch { 'test_token' }.times(1)
      stub(Dude::StatusLine::SpendCache).new { spend_cache_instance }
      stub(spend_cache_instance).fetch { 100.5 }
      stub(Dude::StatusLine::AnthropicSpendClient).new(anything) { Object.new }
      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint_instance }
      stub(checkpoint_instance).read { { spent: 50.0, date: Date.today.to_s, month_spend_at_day_start: 100.5, days_left: 15 } }
      stub(checkpoint_instance).write(anything) { nil }
      stub(Dude::StatusLine::EnterpriseSpend).new(anything, anything) { enterprise_spend_instance }
      stub(enterprise_spend_instance).daily_bar { '☀️ enterprise_daily' }
      stub(enterprise_spend_instance).monthly_bar { '🌙 enterprise_monthly' }
    end

    it 'builds status line with enterprise spend bars' do
      sut = Dude::StatusLine::Runner.new(session_input)
      output = capture_output { sut.run }

      expect(output).to include('☀️ enterprise_daily')
      expect(output).to include('🌙 enterprise_monthly')
    end

    it 'memoizes token fetch so it runs exactly once for both daily and monthly sections' do
      sut = Dude::StatusLine::Runner.new(session_input)
      capture_output { sut.run }
    end
  end

  describe 'Enterprise account with empty token' do
    let(:session_input) { '{}' }

    before do
      stub(Dude::StatusLine::AnthropicToken).fetch { '' }
    end

    it 'shows context and models only, gracefully skips spend bars' do
      sut = Dude::StatusLine::Runner.new(session_input)
      output = capture_output { sut.run }

      expect(output).not_to include('☀️ enterprise_daily')
      expect(output).not_to include('🌙 enterprise_monthly')
    end
  end

  describe 'Legacy checkpoint missing lock fields on same day' do
    let(:session_input) { '{}' }
    let(:enterprise_spend_instance) { Object.new }
    let(:spend_cache_instance) { Object.new }
    let(:checkpoint_instance) { Object.new }
    let(:today) { Date.today.to_s }

    before do
      mock(Dude::StatusLine::AnthropicToken).fetch { 'test_token' }.times(1)
      stub(Dude::StatusLine::SpendCache).new { spend_cache_instance }
      stub(spend_cache_instance).fetch { 100.5 }
      stub(Dude::StatusLine::AnthropicSpendClient).new(anything) { Object.new }
      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint_instance }
      stub(checkpoint_instance).read { { spent: 0, date: today } }
      mock(checkpoint_instance).write(
        spent: 100.5,
        date: today,
        month_spend_at_day_start: 100.5,
        days_left: anything
      ) { nil }
      stub(Dude::StatusLine::EnterpriseSpend).new(anything, anything) { enterprise_spend_instance }
      stub(enterprise_spend_instance).daily_bar { '☀️ enterprise_daily' }
      stub(enterprise_spend_instance).monthly_bar { '🌙 enterprise_monthly' }
    end

    it 'writes lock even though date matches today, when lock fields are missing' do
      sut = Dude::StatusLine::Runner.new(session_input)
      output = capture_output { sut.run }

      expect(output).to include('☀️ enterprise_daily')
    end
  end
end
