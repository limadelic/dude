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
      expect(checkpoint_data[:spent]).to eq(0)
      expect(checkpoint_data[:date]).to eq('2026-06-15')
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
      checkpoint.write(spent: 5.5, date: '2026-06-15')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:spent]).to eq(5.5)
      expect(checkpoint_data[:date]).to eq('2026-06-15')
    end

    it 'detects day rollover and updates checkpoint with yesterdays total' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 50.0 }
      stub(Time).now { Time.new(2026, 6, 3, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 3) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(spent: 20.0, date: '2026-06-02')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:spent]).to eq(50.0)
      expect(checkpoint_data[:date]).to eq('2026-06-03')
    end

    it 'does not update checkpoint on same day' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 30.0 }
      stub(Time).now { Time.new(2026, 6, 2, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 2) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(spent: 15.0, date: '2026-06-02')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:spent]).to eq(15.0)
      expect(checkpoint_data[:date]).to eq('2026-06-02')
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
      expect(checkpoint_data[:date]).to eq('2026-06-02')
    end

    it 'updates checkpoint with current monthly spend on rollover' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 75.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(spent: 50.0, date: '2026-06-14')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      sut.to_s

      checkpoint_data = checkpoint.read
      expect(checkpoint_data[:spent]).to eq(75.0)
      expect(checkpoint_data[:date]).to eq('2026-06-15')
    end

    it 'returns 0 at midnight (0 mins into day)' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 5.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(spent: 0.0, date: '2026-06-15')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      expect(output).to include("\033[32m")
      expect(output).to include("░░░░░░░░░")
    end

    it 'calculates rate_per_min at 30 mins, spent $5' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 5.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 30, 0) }
      stub(Date).today { Date.new(2026, 6, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(spent: 0.0, date: '2026-06-15')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      baseline_rate = 175.0 / 1440.0
      today_spend = 5.0
      mins_since_midnight = 30
      rate_per_min = today_spend / mins_since_midnight.to_f
      pct = (rate_per_min / baseline_rate) * 100

      expect(today_spend).to eq(5.0)
      expect(rate_per_min).to be_within(0.01).of(0.167)
      expect(pct).to be_within(1).of(137)
      expect(output).to include("\033[38;5;226m")
    end

    it 'calculates rate_per_min at 1 hour, spent $10' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 10.0 }
      stub(Time).now { Time.new(2026, 6, 15, 1, 0, 0) }
      stub(Date).today { Date.new(2026, 6, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(spent: 0.0, date: '2026-06-15')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      baseline_rate = 175.0 / 1440.0
      today_spend = 10.0
      mins_since_midnight = 60
      rate_per_min = today_spend / mins_since_midnight.to_f
      pct = (rate_per_min / baseline_rate) * 100

      expect(rate_per_min).to be_within(0.01).of(0.167)
      expect(pct).to be_within(1).of(137)
      expect(output).to include("\033[38;5;226m")
    end

    it 'calculates rate_per_min at 10 mins, spent $1' do
      stub(token_fetcher).fetch { 'token' }
      stub(client).fetch { 1.0 }
      stub(Time).now { Time.new(2026, 6, 15, 0, 10, 0) }
      stub(Date).today { Date.new(2026, 6, 15) }

      checkpoint = Dude::StatusLine::DailyCheckpoint.new(temp_status_file.path)
      checkpoint.write(spent: 0.0, date: '2026-06-15')

      stub(Dude::StatusLine::DailyCheckpoint).new { checkpoint }

      output = sut.to_s

      baseline_rate = 175.0 / 1440.0
      today_spend = 1.0
      mins_since_midnight = 10
      rate_per_min = today_spend / mins_since_midnight.to_f
      pct = (rate_per_min / baseline_rate) * 100

      expect(rate_per_min).to eq(0.1)
      expect(pct).to be_within(1).of(82)
      expect(output).to include("\033[32m")
    end
  end
end
