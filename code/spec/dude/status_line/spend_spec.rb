require_relative '../../spec_helper'
require 'dude/status_line/spend'
require 'dude/status_line/daily_checkpoint'
require 'tempfile'
require 'date'

describe Dude::StatusLine::Spend do
  include RR::DSL
  let(:sut) { described_class.new(token_fetcher, client) }
  let(:token_fetcher) { Object.new }
  let(:client) { Object.new }
  let(:temp_status_file) { Tempfile.new('status.json') }

  before do
    allow_message_expectations_on_nil
  end

  after do
    temp_status_file.unlink if temp_status_file
  end

  describe '#to_s' do
    it 'shows green bar when daily rate below 33%' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 10.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }

      output = sut.to_s

      expect(output).to include("\033[32m")
      expect(output).to include('💰')
      expect(output).to include('█')
    end

    it 'calculates daily rate as monthly_spend / day_of_month' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 100.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }

      output = sut.to_s

      daily_rate = 100.0 / 15
      expected_pct = (daily_rate / 8.75 * 100).round
      expect(expected_pct).to eq(76)
      expect(output).to include('█')
    end

    it 'shows yellow bar when daily rate 33-66%' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 50.0 }
      stub(Time).now { Time.new(2026, 6, 10, 0, 0, 0) }

      output = sut.to_s

      expect(output).to include("\033[38;5;226m")
    end

    it 'shows red bar when daily rate above 66%' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 150.0 }
      stub(Time).now { Time.new(2026, 6, 5, 0, 0, 0) }

      output = sut.to_s

      expect(output).to include("\033[31m")
    end

    it 'shows empty bar when no token available' do
      stub(token_fetcher).fetch { '' }

      output = sut.to_s

      expect(output).to include('💰')
      expect(output).to include('░░░░░░░░░')
    end

    it 'shows empty bar when API fails' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 0.0 }

      output = sut.to_s

      expect(output).to include('░░░░░░░░░')
    end

    it 'initializes checkpoint on first render with no checkpoint' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 10.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:daily_checkpoint_month_total]).to eq(0)
      expect(checkpoint_data[:daily_checkpoint_date]).to eq('2026-06-15')
    end

    it 'preserves existing checkpoint on subsequent renders' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 10.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s
      initial_data = checkpoint.read

      sut.to_s
      subsequent_data = checkpoint.read

      expect(subsequent_data).to eq(initial_data)
    end

    it 'preserves checkpoint from previous session' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 10.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 5.5, date: '2026-06-15')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:daily_checkpoint_month_total]).to eq(5.5)
      expect(checkpoint_data[:daily_checkpoint_date]).to eq('2026-06-15')
    end

    it 'detects day rollover and updates checkpoint with yesterdays total' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 50.0 }
      stub(Time).now { Time.new(2026, 6, 3, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 3) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 20.0, date: '2026-06-02')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:daily_checkpoint_month_total]).to eq(50.0)
      expect(checkpoint_data[:daily_checkpoint_date]).to eq('2026-06-03')
    end

    it 'does not update checkpoint on same day' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 30.0 }
      stub(Time).now { Time.new(2026, 6, 2, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 2) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 15.0, date: '2026-06-02')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:daily_checkpoint_month_total]).to eq(15.0)
      expect(checkpoint_data[:daily_checkpoint_date]).to eq('2026-06-02')
    end

    it 'initializes to today when first render is on day 2 of month' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 10.0 }
      stub(Time).now { Time.new(2026, 6, 2, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 2) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:daily_checkpoint_date]).to eq('2026-06-02')
    end

    it 'updates checkpoint with current monthly spend on rollover' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 75.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 50.0, date: '2026-06-14')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:daily_checkpoint_month_total]).to eq(75.0)
      expect(checkpoint_data[:daily_checkpoint_date]).to eq('2026-06-15')
    end

    it 'calculates today_target using remaining budget and remaining days (june 3 example)' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 3.56 }
      stub(Time).now { Time.new(2026, 6, 3, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 3) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 1.50, date: '2026-06-02')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      today_actual = 3.56 - 1.50
      remaining_budget = 175.0 - 3.56
      remaining_days = 28
      today_target = remaining_budget / remaining_days
      expected_pct = ((today_actual / today_target) * 100).round

      expect(today_actual).to eq(2.06)
      expect(remaining_budget).to eq(171.44)
      expect(today_target).to be_within(0.01).of(6.12)
      expect(expected_pct).to eq(34)
      expect(output).to include("\033[32m")
    end

    it 'handles february with 28 days' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 20.0 }
      stub(Time).now { Time.new(2026, 2, 15, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 2, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 10.0, date: '2026-02-14')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      today_actual = 20.0 - 10.0
      remaining_budget = 175.0 - 20.0
      remaining_days = 14
      today_target = remaining_budget / remaining_days
      expected_pct = ((today_actual / today_target) * 100).round

      expect(remaining_days).to eq(14)
      expect(today_target).to be_within(0.1).of(11.07)
      expect(expected_pct).to eq(90)
    end

    it 'handles may with 31 days' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 50.0 }
      stub(Time).now { Time.new(2026, 5, 20, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 5, 20) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 40.0, date: '2026-05-19')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      today_actual = 50.0 - 40.0
      remaining_budget = 175.0 - 50.0
      remaining_days = 12
      today_target = remaining_budget / remaining_days
      expected_pct = ((today_actual / today_target) * 100).round

      expect(remaining_days).to eq(12)
      expect(today_target).to be_within(0.1).of(10.42)
      expect(expected_pct).to eq(96)
    end

    it 'handles last day of month (1 day remaining)' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 170.0 }
      stub(Time).now { Time.new(2026, 6, 30, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 30) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 165.0, date: '2026-06-29')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      today_actual = 170.0 - 165.0
      remaining_budget = 175.0 - 170.0
      remaining_days = 1
      today_target = remaining_budget / remaining_days
      expected_pct = ((today_actual / today_target) * 100).round

      expect(today_actual).to eq(5.0)
      expect(today_target).to eq(5.0)
      expect(expected_pct).to eq(100)
    end

    it 'returns 100% when budget fully spent (today_target approaches 0)' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 175.0 }
      stub(Time).now { Time.new(2026, 6, 20, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 20) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 170.0, date: '2026-06-19')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      today_actual = 175.0 - 170.0
      remaining_budget = 175.0 - 175.0
      remaining_days = 11

      expect(remaining_budget).to eq(0)
      expect(output).to include('█████████')
    end

    it 'handles safe division when monthly_spend exceeds budget' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 180.0 }
      stub(Time).now { Time.new(2026, 6, 25, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 25) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(month_total: 170.0, date: '2026-06-24')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      today_actual = 180.0 - 170.0
      remaining_budget = 175.0 - 180.0
      remaining_days = 6
      expected_pct = (180.0 / 175.0 * 100).round

      expect(remaining_budget).to be < 0
      expect(expected_pct).to eq(103)
      expect(output).to include('█')
    end
  end
end
