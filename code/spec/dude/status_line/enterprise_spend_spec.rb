require_relative '../../spec_helper'
require 'dude/status_line/enterprise_spend'
require 'dude/status_line/daily_checkpoint'
require 'tempfile'
require 'date'

describe Dude::StatusLine::EnterpriseSpend do
  include RR::DSL

  let(:temp_file) { Tempfile.new('status.json') }
  let(:checkpoint_path) { temp_file.path }
  let(:checkpoint) { Dude::StatusLine::DailyCheckpoint.new(checkpoint_path) }

  let(:sut) do
    described_class.new(month_spend, today_spend, time_provider, date_provider, checkpoint)
  end
  let(:month_spend) { 50.0 }
  let(:today_spend) { 10.0 }
  let(:time_provider) { proc { Time.new(2026, 6, 15, 12, 0, 0) } }
  let(:date_provider) { proc { Date.new(2026, 6, 15) } }

  before do
    allow_message_expectations_on_nil
  end

  after do
    temp_file.unlink if temp_file
  end

  describe '#daily_bar' do
    it 'returns nil when daily_budget is not locked' do
      result = sut.daily_bar

      expect(result).to be_nil
    end

    it 'returns bar with correct fill when daily_budget is locked' do
      cp = Dude::StatusLine::DailyCheckpoint.new(checkpoint_path)
      cp.write(
        spent: month_spend,
        date: '2026-06-15',
        month_spend_at_day_start: 40.0,
        days_left: 15
      )

      result = sut.daily_bar

      expect(result).not_to be_nil
      expect(result).to include('☀️')
    end

    it 'calculates fill percentage as today_spend / daily_budget' do
      cp = Dude::StatusLine::DailyCheckpoint.new(checkpoint_path)
      cp.write(
        spent: 50.0,
        date: '2026-06-15',
        month_spend_at_day_start: 40.0,
        days_left: 15
      )

      daily_budget = (175.0 - 40.0) / 15.0

      result = sut.daily_bar

      fill_pct = (10.0 / daily_budget) * 100

      expect(fill_pct).to be_within(1).of(111)
      expect(result).to include('█████████')
    end

    it 'shows correct color based on pace ratio' do
      cp = Dude::StatusLine::DailyCheckpoint.new(checkpoint_path)
      cp.write(
        spent: 50.0,
        date: '2026-06-15',
        month_spend_at_day_start: 40.0,
        days_left: 15
      )

      result = sut.daily_bar

      expect(result).not_to be_nil
      expect(result).to include('☀️')
    end

    it 'shows yellow when pace is medium (1 < fill/elapsed <= 2)' do
      half_day_provider = proc { Time.new(2026, 6, 15, 12, 0, 0) }
      cp = Dude::StatusLine::DailyCheckpoint.new(checkpoint_path)
      cp.write(
        spent: 50.0,
        date: '2026-06-15',
        month_spend_at_day_start: 40.0,
        days_left: 15
      )
      sut_half_day = described_class.new(
        50.0,
        15.0,
        half_day_provider,
        date_provider,
        cp
      )

      result = sut_half_day.daily_bar

      expect(result).to include("\033[38;5;226m")
    end

    it 'returns nil when days_left is 0 (checkpoint today, no crash)' do
      cp = Dude::StatusLine::DailyCheckpoint.new(checkpoint_path)
      cp.write(
        spent: 50.0,
        date: '2026-06-15',
        month_spend_at_day_start: 40.0,
        days_left: 0
      )
      sut_end_of_month = described_class.new(50.0, 10.0, time_provider, date_provider, cp)

      result = sut_end_of_month.daily_bar

      expect(result).to be_nil
    end
  end

  describe '#monthly_bar' do
    it 'returns bar with correct fill' do
      result = sut.monthly_bar

      expect(result).not_to be_nil
      expect(result).to include('🌙')
    end

    it 'calculates fill percentage as month_spend / MONTHLY_BUDGET' do
      result = sut.monthly_bar

      fill_pct = (50.0 / 175.0) * 100

      expect(fill_pct).to be_within(1).of(28.6)
      expect(result).to include('███░░░░░░')
    end

    it 'shows correct color based on pace' do
      result = sut.monthly_bar

      expect(result).to include('🌙')
    end

    it 'shows higher fill when more of month is spent' do
      sut_later = described_class.new(100.0, 50.0, time_provider, date_provider, checkpoint)

      result = sut_later.monthly_bar

      expect(result).to include('🌙')
    end
  end

  describe 'daily_budget lock' do
    it 'keeps daily_budget locked when month_spend increases mid-day' do
      bar1 = sut.daily_bar

      sut_later_spend = described_class.new(60.0, 20.0, time_provider, date_provider, checkpoint)
      bar2 = sut_later_spend.daily_bar

      expect(bar1).to be_nil
      expect(bar2).to be_nil
    end
  end
end
