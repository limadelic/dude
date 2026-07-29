require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/request_counter'

describe Dude::Transcript::RequestCounter do
  include RR::DSL

  let(:sut) { described_class.new }

  describe '#count' do
    it 'returns empty hash when file does not exist' do
      stub(File).exist? { false }

      result = sut.count('/nonexistent/path.jsonl')

      expect(result).to eq({})
    end

    it 'returns empty hash when file is not readable' do
      stub(File).exist? { true }
      stub(File).read { raise IOError }

      result = sut.count('/unreadable/path.jsonl')

      expect(result).to eq({})
    end

    it 'counts a single assistant request' do
      content = '{"message":{"model":"claude-opus-5","id":"msg-1"}}'
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'opus' => 1 })
    end

    it 'counts multiple assistant requests' do
      content = [
        '{"message":{"model":"claude-opus-5","id":"msg-1"}}',
        '{"message":{"model":"claude-haiku-4-5-20251001","id":"msg-2"}}'
      ].join("\n")
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'opus' => 1, 'haiku' => 1 })
    end

    it 'deduplicates by message id' do
      content = [
        '{"message":{"model":"claude-opus-5","id":"msg-1"}}',
        '{"message":{"model":"claude-opus-5","id":"msg-1"}}',
        '{"message":{"model":"claude-opus-5","id":"msg-1"}}'
      ].join("\n")
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'opus' => 1 })
    end

    it 'extracts model family from model name' do
      content = [
        '{"message":{"model":"claude-sonnet-5","id":"msg-1"}}',
        '{"message":{"model":"claude-fable-5","id":"msg-2"}}'
      ].join("\n")
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'sonnet' => 1, 'fable' => 1 })
    end

    it 'ignores non-assistant lines' do
      content = [
        '{"type":"user","text":"hello"}',
        '{"message":{"model":"claude-opus-5","id":"msg-1"}}'
      ].join("\n")
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'opus' => 1 })
    end

    it 'ignores entries without model' do
      content = [
        '{"message":{"id":"msg-1"}}',
        '{"message":{"model":"claude-opus-5","id":"msg-2"}}'
      ].join("\n")
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'opus' => 1 })
    end

    it 'ignores malformed JSON lines' do
      content = [
        'not json',
        '{"message":{"model":"claude-opus-5","id":"msg-1"}}'
      ].join("\n")
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'opus' => 1 })
    end

    it 'counts all four model families' do
      content = [
        '{"message":{"model":"claude-opus-5","id":"msg-1"}}',
        '{"message":{"model":"claude-opus-5","id":"msg-2"}}',
        '{"message":{"model":"claude-haiku-4-5-20251001","id":"msg-3"}}',
        '{"message":{"model":"claude-sonnet-5","id":"msg-4"}}',
        '{"message":{"model":"claude-fable-5","id":"msg-5"}}'
      ].join("\n")
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'opus' => 2, 'haiku' => 1, 'sonnet' => 1, 'fable' => 1 })
    end

    it 'ignores entries with missing id' do
      content = [
        '{"message":{"model":"claude-opus-5"}}',
        '{"message":{"model":"claude-opus-5","id":"msg-1"}}'
      ].join("\n")
      stub(File).exist? { true }
      stub(File).read { content }

      result = sut.count('/path/transcript.jsonl')

      expect(result).to eq({ 'opus' => 1 })
    end
  end
end
