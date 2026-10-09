require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/usage_cache_store'
require_relative '../../lib/dude/transcript/usage_cache'

describe Dude::Transcript::UsageCacheStore do
  include RR::DSL
  let(:sut) { described_class.new(cache_path) }

  let(:cache_path) { '/home/user/.claude/dude/usage_cache.json' }
  let(:price_table) { double(cost: 1.5) }

  let(:window_name) { '5h' }
  let(:window_start) { 1000 }
  let(:usage_record) do
    {
      id: 'msg-1',
      model: 'claude-opus-5',
      usage: { 'input_tokens' => 100 },
      epoch: 2000,
      session: 'sess-a'
    }
  end

  describe '#load' do
    context 'when cache file exists with valid JSON' do
      let(:cache_data) do
        {
          files: {},
          windows: {
            window_name => {
              start: window_start,
              costs: { 'sess-a' => 1.5 },
              seen_ids: ['msg-1']
            }
          }
        }
      end

      before do
        stub(File).exist?(cache_path) { true }
        stub(JSON).load_file(cache_path) { cache_data }
      end

      it 'loads cache data from file' do
        cache = sut.load(price_table)

        expect(cache).to be_a(Dude::Transcript::UsageCache)
        expect(cache.window_start(window_name)).to eq(window_start)
      end

      it 'fills cache with from_h' do
        cache = sut.load(price_table)

        expect(cache.has_seen_id?(window_name, 'msg-1')).to be true
      end
    end

    context 'when cache file does not exist' do
      before do
        stub(File).exist?(cache_path) { false }
      end

      it 'returns empty cache' do
        cache = sut.load(price_table)

        expect(cache).to be_a(Dude::Transcript::UsageCache)
        expect(cache.window_start(window_name)).to eq(Float::INFINITY)
      end
    end

    context 'when JSON is invalid' do
      before do
        stub(File).exist?(cache_path) { true }
        stub(JSON).load_file(cache_path) { raise JSON::ParserError.new('bad json') }
      end

      it 'returns empty cache on parse error' do
        cache = sut.load(price_table)

        expect(cache).to be_a(Dude::Transcript::UsageCache)
      end
    end

    context 'when file raises unexpected error' do
      before do
        stub(File).exist?(cache_path) { true }
        err = StandardError.new('unexpected')
        stub(JSON).load_file(cache_path) { raise err }
      end

      it 'returns empty cache on error' do
        cache = sut.load(price_table)

        expect(cache).to be_a(Dude::Transcript::UsageCache)
      end
    end
  end

  describe '#save' do
    let(:cache) { Dude::Transcript::UsageCache.new(price_table) }

    before do
      cache.set_window_start(window_name, window_start)
      cache.add(window_name, usage_record)
      stub(FileUtils).mkdir_p
      stub(File).write(is_a(String), is_a(String))
      stub(File).rename(is_a(String), cache_path)
    end

    it 'writes valid JSON with cache state' do
      written_json = nil
      stub(File).write(is_a(String), is_a(String)) { |path, data|
        written_json = JSON.parse(data)
      }

      sut.save(cache)

      expect(written_json).to have_key('files')
      expect(written_json).to have_key('windows')
      expect(written_json['windows'][window_name]['start']).to eq(window_start)
      expect(written_json['windows'][window_name]['costs']['sess-a']).to eq(1.5)
    end

    it 'creates parent directory' do
      mock(FileUtils).mkdir_p(File.dirname(cache_path))

      sut.save(cache)
    end
  end

  describe 'save and load roundtrip' do
    let(:cache) { Dude::Transcript::UsageCache.new(price_table) }
    let(:cache_data) do
      {
        files: { '/path/to/file' => [12345, 5000] },
        windows: {
          window_name => {
            start: window_start,
            costs: { 'sess-a' => 1.5 },
            seen_ids: ['msg-1']
          }
        }
      }
    end

    before do
      cache.set_window_start(window_name, window_start)
      cache.add(window_name, usage_record)
      cache.set_file_state('/path/to/file', 12345, 5000)

      stub(FileUtils).mkdir_p
      stub(File).write(is_a(String), is_a(String))
      stub(File).rename(is_a(String), cache_path)
      stub(File).exist?(cache_path) { true }
      stub(JSON).load_file(cache_path) { cache_data }
    end

    it 'preserves all state through save and load' do
      sut.save(cache)
      loaded_cache = sut.load(price_table)

      expect(loaded_cache.window_start(window_name)).to eq(window_start)
      expect(loaded_cache.has_seen_id?(window_name, 'msg-1')).to be true
      mtime, offset = loaded_cache.file_state('/path/to/file')
      expect(mtime).to eq(12345)
      expect(offset).to eq(5000)
    end
  end
end
