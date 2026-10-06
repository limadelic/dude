require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/deduper'

describe Dude::Transcript::Deduper do
  include RR::DSL

  let(:sut) { described_class.new }

  let(:record_one) do
    {
      id: 'msg-1',
      model: 'claude-opus-5',
      usage: { 'input_tokens' => 100, 'output_tokens' => 50 },
      epoch: 1000,
      session: 'sess-1'
    }
  end

  let(:record_two) do
    {
      id: 'msg-2',
      model: 'claude-haiku-4-5-20251001',
      usage: { 'input_tokens' => 10, 'output_tokens' => 5 },
      epoch: 2000,
      session: 'sess-1'
    }
  end

  let(:records) { [record_one, record_two] }

  def record_by_id(result, id)
    result.find { |r| r[:id] == id }
  end

  describe '#call' do
    let(:input) { records }

    it 'returns all records when no duplicates' do
      result = sut.call(input)

      expect(result.length).to eq(2)
      expect(result).to include(record_one)
      expect(result).to include(record_two)
    end

    context 'with duplicate ids' do
      let(:input) do
        duplicate_later = record_one.merge(epoch: 3000)
        [record_one, duplicate_later, record_two]
      end

      it 'keeps only earliest epoch when id duplicates' do
        result = sut.call(input)

        expect(result.length).to eq(2)
        expect(record_by_id(result, 'msg-1')[:epoch]).to eq(1000)
      end
    end

    context 'with some nil ids' do
      let(:input) do
        no_id = record_one.merge(id: nil)
        [record_one, no_id, record_two]
      end

      it 'drops records with nil id' do
        result = sut.call(input)

        expect(result.length).to eq(2)
        expect(result).to include(record_one)
        expect(result).to include(record_two)
      end
    end

    context 'with multiple duplicates' do
      let(:input) do
        dup_1_mid = record_one.merge(epoch: 2500)
        dup_1_late = record_one.merge(epoch: 5000)
        [dup_1_mid, record_one, dup_1_late, record_two]
      end

      it 'keeps multiple duplicates with earliest epoch' do
        result = sut.call(input)

        expect(result.length).to eq(2)
        expect(record_by_id(result, 'msg-1')[:epoch]).to eq(1000)
      end
    end

    context 'with all nil ids' do
      let(:input) do
        no_id_1 = record_one.merge(id: nil)
        no_id_2 = record_two.merge(id: nil)
        [no_id_1, no_id_2]
      end

      it 'handles all nil ids by dropping them' do
        result = sut.call(input)

        expect(result).to eq([])
      end
    end

    context 'with empty records' do
      let(:input) { [] }

      it 'handles empty records' do
        result = sut.call(input)

        expect(result).to eq([])
      end
    end

    context 'when deduping preserves data' do
      let(:input) do
        dup = record_one.merge(
          epoch: 3000,
          model: 'claude-sonnet-5',
          usage: { 'input_tokens' => 200, 'output_tokens' => 100 }
        )
        [record_one, dup]
      end

      it 'preserves record data when deduping' do
        result = sut.call(input)

        kept = record_by_id(result, 'msg-1')
        expect(kept[:model]).to eq('claude-opus-5')
        expect(kept[:usage]).to eq(
          { 'input_tokens' => 100, 'output_tokens' => 50 }
        )
      end
    end
  end
end
