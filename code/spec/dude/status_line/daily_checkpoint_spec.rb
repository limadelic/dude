require_relative '../../spec_helper'
require 'dude/status_line/daily_checkpoint'

describe Dude::StatusLine::DailyCheckpoint do
  include RR::DSL
  let(:status_path) { File.expand_path('~/.claude/status.json') }
  let(:sut) { described_class.new(status_path) }

  describe '#read' do
    it 'returns empty hash when file does not exist' do
      stub(File).exist?(status_path) { false }

      result = sut.read

      expect(result).to eq({})
    end

    it 'returns checkpoint data when file has valid data' do
      file_content = {
        'spent' => 42,
        'date' => '2026-06-03',
        'color' => 'green'
      }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { JSON.generate(file_content) }

      result = sut.read

      expect(result).to eq(
        {
          spent: 42,
          date: '2026-06-03'
        }
      )
    end

    it 'returns empty hash when JSON is corrupted' do
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { 'invalid json' }

      result = sut.read

      expect(result).to eq({})
    end

    it 'returns only keys that exist in file' do
      file_content = {
        'date' => '2026-06-03'
      }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { JSON.generate(file_content) }

      result = sut.read

      expect(result).to eq({ date: '2026-06-03' })
    end

    it 'ignores other keys in the file' do
      file_content = {
        'spent' => 42,
        'color' => 'blue',
        'other_key' => 'ignored'
      }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { JSON.generate(file_content) }

      result = sut.read

      expect(result).to eq({ spent: 42 })
    end
  end

  describe '#write' do
    it 'creates file when it does not exist' do
      stub(File).exist?(status_path) { false }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(spent: 10, date: '2026-06-03')

      expect(written_data['spent']).to eq(10)
      expect(written_data['date']).to eq('2026-06-03')
    end

    it 'updates existing file and preserves other keys' do
      existing_content = { 'color' => 'green', 'other' => 'value' }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { JSON.generate(existing_content) }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(spent: 15, date: '2026-06-04')

      expect(written_data['spent']).to eq(15)
      expect(written_data['date']).to eq('2026-06-04')
      expect(written_data['color']).to eq('green')
      expect(written_data['other']).to eq('value')
    end

    it 'overwrites existing checkpoint values' do
      existing_content = { 'spent' => 5, 'date' => '2026-06-02' }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { JSON.generate(existing_content) }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(spent: 20, date: '2026-06-03')

      expect(written_data['spent']).to eq(20)
      expect(written_data['date']).to eq('2026-06-03')
    end

    it 'uses default path when none provided' do
      sut_default = described_class.new
      default_path = File.expand_path('~/.claude/status.json')
      stub(File).exist?(default_path) { true }
      stub(File).read(default_path) { JSON.generate({}) }
      written_data = nil
      tmp_path = default_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, default_path)

      sut_default.write(spent: 5, date: '2026-06-03')

      expect(written_data['spent']).to eq(5)
    end

    it 'writes valid JSON format' do
      stub(File).exist?(status_path) { false }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(spent: 8, date: '2026-06-03')

      expect(written_data).to be_a(Hash)
      expect(written_data['spent']).to eq(8)
      expect(written_data['date']).to eq('2026-06-03')
    end

    it 'uses atomic write with .tmp file' do
      tmp_path = status_path + '.tmp'
      stub(File).exist?(status_path) { false }
      write_called = false
      rename_called = false

      stub(File).write(tmp_path, is_a(String)) { write_called = true }
      stub(File).rename(tmp_path, status_path) { rename_called = true }

      sut.write(spent: 12, date: '2026-06-03')

      expect(write_called).to be true
      expect(rename_called).to be true
    end

    it 'writes to .tmp then renames to final path' do
      tmp_path = status_path + '.tmp'
      stub(File).exist?(status_path) { false }
      call_order = []

      stub(File).write(tmp_path, is_a(String)) { call_order << :write }
      stub(File).rename(tmp_path, status_path) { call_order << :rename }

      sut.write(spent: 12, date: '2026-06-03')

      expect(call_order).to eq([:write, :rename])
    end

    it 'snapshots month_spend_at_day_start and days_left on new day' do
      stub(File).exist?(status_path) { false }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(
        spent: 100, date: '2026-06-15', month_spend_at_day_start: 500,
        days_left: 16
      )

      expect(written_data['month_spend_at_day_start']).to eq(500)
      expect(written_data['days_left']).to eq(16)
    end

    it 'persists lock values with checkpoint fields' do
      stub(File).exist?(status_path) { false }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(
        spent: 75, date: '2026-06-15', month_spend_at_day_start: 450,
        days_left: 16
      )

      expect(written_data['spent']).to eq(75)
      expect(written_data['date']).to eq('2026-06-15')
      expect(written_data['month_spend_at_day_start']).to eq(450)
      expect(written_data['days_left']).to eq(16)
    end

    it 'omits lock values when not provided' do
      stub(File).exist?(status_path) { false }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(spent: 90, date: '2026-06-15')

      expect(written_data).not_to have_key('month_spend_at_day_start')
      expect(written_data).not_to have_key('days_left')
    end
  end

  describe 'daily budget lock behavior' do
    it 'reads locked values when present' do
      file_content = {
        'spent' => 100,
        'date' => '2026-06-15',
        'month_spend_at_day_start' => 500,
        'days_left' => 16
      }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { JSON.generate(file_content) }

      result = sut.read

      expect(result[:month_spend_at_day_start]).to eq(500)
      expect(result[:days_left]).to eq(16)
    end

    it 'keeps locked values on same day re-read' do
      initial_content = {
        'spent' => 100,
        'date' => '2026-06-15',
        'month_spend_at_day_start' => 500,
        'days_left' => 16
      }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { JSON.generate(initial_content) }

      result = sut.read

      expect(result[:month_spend_at_day_start]).to eq(500)
      expect(result[:days_left]).to eq(16)
    end

    it 'allows fresh lock values on new day' do
      existing_content = {
        'spent' => 100,
        'date' => '2026-06-15',
        'month_spend_at_day_start' => 500,
        'days_left' => 16
      }
      stub(File).exist?(status_path) { true }
      stub(File).read(status_path) { JSON.generate(existing_content) }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(
        spent: 150, date: '2026-06-16', month_spend_at_day_start: 480,
        days_left: 15
      )

      expect(written_data['date']).to eq('2026-06-16')
      expect(written_data['month_spend_at_day_start']).to eq(480)
      expect(written_data['days_left']).to eq(15)
    end

    it 'maintains backward compatibility with existing fields' do
      stub(File).exist?(status_path) { false }
      written_data = nil
      tmp_path = status_path + '.tmp'
      stub(File).write(tmp_path, is_a(String)) do |path, data|
        written_data = JSON.parse(data)
      end
      stub(File).rename(tmp_path, status_path)

      sut.write(
        spent: 120, date: '2026-06-15', month_spend_at_day_start: 500,
        days_left: 16
      )

      expect(written_data['spent']).to eq(120)
      expect(written_data['date']).to eq('2026-06-15')
    end
  end
end
