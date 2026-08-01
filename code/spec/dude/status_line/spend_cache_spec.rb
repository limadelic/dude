require_relative '../../spec_helper'
require 'dude/status_line/spend_cache'

describe Dude::StatusLine::SpendCache do
  include RR::DSL
  let(:cache_path) { File.expand_path('~/.claude/.spend-cache.json') }
  let(:sut) { described_class.new(cache_path) }

  describe '#fetch' do
    it 'returns cached value when cache is fresh (< 5 min)' do
      cached = {
        'updated_at' => (Time.now - 60).iso8601,
        'spend' => 25.50
      }
      stub(File).exist?(cache_path) { true }
      stub(File).read(cache_path) { JSON.generate(cached) }

      spend = sut.fetch { fail 'should not call block' }

      expect(spend).to eq(25.50)
    end

    it 'calls block and updates cache when cache is stale (> 5 min)' do
      cached = {
        'updated_at' => (Time.now - 400).iso8601,
        'spend' => 20.00
      }
      stub(File).exist?(cache_path) { true }
      stub(File).read(cache_path) { JSON.generate(cached) }
      stub(File).write(cache_path, anything) { nil }

      spend = sut.fetch { 35.75 }

      expect(spend).to eq(35.75)
    end

    it 'calls block when cache missing' do
      stub(File).exist?(cache_path) { false }
      stub(File).write(cache_path, anything) { nil }

      spend = sut.fetch { 42.00 }

      expect(spend).to eq(42.00)
    end

    it 'writes cache in JSON format' do
      stub(File).exist?(cache_path) { false }
      written_data = nil
      stub(File).write(cache_path, is_a(String)) { |path, data|
        written_data = JSON.parse(data)
      }

      sut.fetch { 15.5 }

      expect(written_data['spend']).to eq(15.5)
      expect(written_data['updated_at']).to match(/^\d{4}-\d{2}-\d{2}T/)
    end

    it 'returns block value when cache JSON parse fails' do
      stub(File).exist?(cache_path) { true }
      stub(File).read(cache_path) { 'invalid json' }
      stub(File).write(cache_path, anything) { nil }

      spend = sut.fetch { 50.0 }

      expect(spend).to eq(50.0)
    end
  end
end
