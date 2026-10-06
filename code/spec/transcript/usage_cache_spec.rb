require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/usage_cache'

describe Dude::Transcript::UsageCache do
  include RR::DSL

  let(:price_table) { double(cost: 1.5) }
  let(:cache) { described_class.new(price_table) }

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

  let(:file_path) { '/path/to/transcript.jsonl' }
  let(:file_mtime) { 1234567890 }
  let(:file_offset) { 5000 }

  describe '#add' do
    before { cache.set_window_start(window_name, window_start) }

    it 'adds cost when id not seen' do
      cache.add(window_name, usage_record)

      expect(cache.cost(window_name, 'sess-a')).to eq(1.5)
    end

    context 'when id already seen in window' do
      before do
        cache.add(window_name, usage_record)
      end

      it 'ignores duplicate id' do
        cache.add(window_name, usage_record.merge(epoch: 3000))

        expect(cache.cost(window_name, 'sess-a')).to eq(1.5)
      end
    end

    context 'when epoch is before window start' do
      let(:old_record) { usage_record.merge(epoch: 500) }

      it 'ignores record with epoch before start' do
        cache.add(window_name, old_record)

        expect(cache.cost(window_name, 'sess-a')).to eq(0)
      end
    end

    context 'with multiple sessions' do
      let(:usage_a) { { 'input_tokens' => 100 } }
      let(:usage_b) { { 'input_tokens' => 200 } }
      let(:record_sess_b) do
        usage_record.merge(id: 'msg-2', session: 'sess-b', usage: usage_b)
      end

      before do
        stub(price_table).cost('claude-opus-5', usage_a) { 1.0 }
        stub(price_table).cost('claude-opus-5', usage_b) { 2.5 }
        cache.add(window_name, usage_record)
        cache.add(window_name, record_sess_b)
      end

      it 'tracks $ per session' do
        expect(cache.cost(window_name, 'sess-a')).to eq(1.0)
        expect(cache.cost(window_name, 'sess-b')).to eq(2.5)
      end
    end

    context 'with multiple records same session' do
      let(:usage_1) { { 'input_tokens' => 100 } }
      let(:usage_2) { { 'input_tokens' => 200 } }
      let(:record_2) do
        usage_record.merge(id: 'msg-2', epoch: 2500, usage: usage_2)
      end

      before do
        stub(price_table).cost('claude-opus-5', usage_1) { 1.0 }
        stub(price_table).cost('claude-opus-5', usage_2) { 2.0 }
        cache.add(window_name, usage_record)
        cache.add(window_name, record_2)
      end

      it 'accumulates $ per session' do
        expect(cache.cost(window_name, 'sess-a')).to eq(3.0)
      end
    end
  end

  describe '#set_window_start' do
    it 'sets new window start' do
      cache.set_window_start(window_name, window_start)

      expect(cache.window_start(window_name)).to eq(window_start)
    end

    context 'when start changes' do
      before { cache.set_window_start(window_name, window_start) }

      it 'clears cost sums when start differs' do
        cache.add(window_name, usage_record)
        expect(cache.cost(window_name, 'sess-a')).to eq(1.5)

        cache.set_window_start(window_name, 2500)

        expect(cache.cost(window_name, 'sess-a')).to eq(0)
      end

      it 'clears seen ids when start differs' do
        cache.add(window_name, usage_record)
        cache.set_window_start(window_name, 2500)
        cache.add(window_name, usage_record)

        expect(cache.cost(window_name, 'sess-a')).to eq(0)
      end

      it 'preserves file offset when start differs' do
        cache.set_file_state(file_path, file_mtime, file_offset)

        cache.set_window_start(window_name, 2500)

        mtime, offset = cache.file_state(file_path)
        expect(mtime).to eq(file_mtime)
        expect(offset).to eq(file_offset)
      end
    end

    context 'when start unchanged' do
      before { cache.set_window_start(window_name, window_start) }

      it 'keeps cost sums when start unchanged' do
        cache.add(window_name, usage_record)
        cache.set_window_start(window_name, window_start)

        expect(cache.cost(window_name, 'sess-a')).to eq(1.5)
      end
    end
  end

  describe '#set_file_state' do
    it 'stores file mtime and offset' do
      cache.set_file_state(file_path, file_mtime, file_offset)

      mtime, offset = cache.file_state(file_path)
      expect(mtime).to eq(file_mtime)
      expect(offset).to eq(file_offset)
    end

    it 'updates file state' do
      cache.set_file_state(file_path, file_mtime, file_offset)
      cache.set_file_state(file_path, file_mtime + 100, file_offset + 1000)

      mtime, offset = cache.file_state(file_path)
      expect(mtime).to eq(file_mtime + 100)
      expect(offset).to eq(file_offset + 1000)
    end
  end

  describe '#file_state' do
    it 'returns nil for unknown file' do
      result = cache.file_state(file_path)

      expect(result).to be_nil
    end
  end

  describe '#to_h' do
    before do
      cache.set_window_start(window_name, window_start)
      cache.add(window_name, usage_record)
      cache.set_file_state(file_path, file_mtime, file_offset)
    end

    it 'dumps to plain hash' do
      result = cache.to_h

      expect(result).to be_a(Hash)
      expect(result[:files]).to be_a(Hash)
      expect(result[:windows]).to be_a(Hash)
    end

    it 'includes file state in dump' do
      result = cache.to_h

      expect(result[:files][file_path]).to eq([file_mtime, file_offset])
    end

    it 'includes window data in dump' do
      result = cache.to_h

      window_data = result[:windows][window_name]
      expect(window_data[:start]).to eq(window_start)
      expect(window_data[:costs]).to be_a(Hash)
      expect(window_data[:seen_ids]).to be_a(Set)
    end

    it 'includes session cost in window dump' do
      result = cache.to_h

      window_data = result[:windows][window_name]
      expect(window_data[:costs]['sess-a']).to eq(1.5)
    end

    it 'includes seen id in window dump' do
      result = cache.to_h

      window_data = result[:windows][window_name]
      expect(window_data[:seen_ids]).to include('msg-1')
    end
  end

  describe '#from_h' do
    let(:hash_data) do
      {
        files: {
          file_path => [file_mtime, file_offset]
        },
        windows: {
          window_name => {
            start: window_start,
            costs: { 'sess-a' => 1.5 },
            seen_ids: Set.new(['msg-1'])
          }
        }
      }
    end

    it 'loads from plain hash' do
      cache.from_h(hash_data)

      mtime, offset = cache.file_state(file_path)
      expect(mtime).to eq(file_mtime)
      expect(offset).to eq(file_offset)
    end

    it 'loads window start from hash' do
      cache.from_h(hash_data)

      expect(cache.window_start(window_name)).to eq(window_start)
    end

    it 'loads window costs from hash' do
      cache.from_h(hash_data)

      expect(cache.cost(window_name, 'sess-a')).to eq(1.5)
    end

    it 'loads seen ids from hash' do
      cache.from_h(hash_data)

      expect(cache.has_seen_id?(window_name, 'msg-1')).to be true
    end

    context 'with empty hash' do
      let(:hash_data) { { files: {}, windows: {} } }

      it 'handles empty data' do
        cache.from_h(hash_data)

        expect(cache.file_state(file_path)).to be_nil
        expect(cache.cost(window_name, 'sess-a')).to eq(0)
      end
    end
  end

  describe 'roundtrip to_h and from_h' do
    before do
      cache.set_window_start(window_name, window_start)
      cache.add(window_name, usage_record)
      cache.set_file_state(file_path, file_mtime, file_offset)
    end

    it 'preserves all state in roundtrip' do
      dumped = cache.to_h
      new_cache = described_class.new(price_table)
      new_cache.from_h(dumped)

      expect(new_cache.window_start(window_name)).to eq(window_start)
      expect(new_cache.cost(window_name, 'sess-a')).to eq(1.5)
      mtime, offset = new_cache.file_state(file_path)
      expect(mtime).to eq(file_mtime)
      expect(offset).to eq(file_offset)
    end
  end

  describe 'multiple windows' do
    let(:window_2) { 'week' }
    let(:window_2_start) { 500 }
    let(:record_window_2) { usage_record.merge(epoch: 700) }

    before do
      cache.set_window_start(window_name, window_start)
      cache.set_window_start(window_2, window_2_start)
      cache.add(window_name, usage_record)
      cache.add(window_2, record_window_2)
    end

    it 'maintains separate state per window' do
      expect(cache.cost(window_name, 'sess-a')).to eq(1.5)
      expect(cache.cost(window_2, 'sess-a')).to eq(1.5)
    end

    it 'clears only affected window on start change' do
      cache.set_window_start(window_name, 2500)

      expect(cache.cost(window_name, 'sess-a')).to eq(0)
      expect(cache.cost(window_2, 'sess-a')).to eq(1.5)
    end
  end
end
