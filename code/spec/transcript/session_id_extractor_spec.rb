require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/session_id_extractor'

describe Dude::Transcript::SessionIdExtractor do
  let(:sut) { described_class.new }

  describe '#call' do
    let(:path) { '/home/.claude/projects/abc/abc123.jsonl' }

    it 'extracts session id from direct transcript path' do
      result = sut.call(path)

      expect(result).to eq('abc123')
    end

    context 'with subagent transcript' do
      let(:path) do
        '/home/.claude/projects/abc/abc123/subagents/agent-xyz.jsonl'
      end

      it 'extracts parent session id' do
        result = sut.call(path)

        expect(result).to eq('abc123')
      end
    end

    context 'with different session ids' do
      let(:path) { '/var/log/transcripts/sess-abc-def-123.jsonl' }

      it 'extracts session id with special characters' do
        result = sut.call(path)

        expect(result).to eq('sess-abc-def-123')
      end
    end

    context 'with deeply nested subagent path' do
      let(:path) do
        '/data/sessions/parent-sid-999/subagents/agent-abc.jsonl'
      end

      it 'extracts parent session id from nested structure' do
        result = sut.call(path)

        expect(result).to eq('parent-sid-999')
      end
    end

    context 'with path without jsonl extension' do
      let(:path) { '/home/.claude/projects/abc/xyz456' }

      it 'extracts basename as session id' do
        result = sut.call(path)

        expect(result).to eq('xyz456')
      end
    end

    context 'with subagent path without jsonl extension' do
      let(:path) { '/home/.claude/projects/abc/xyz456/subagents/agent-1' }

      it 'extracts parent session id without extension' do
        result = sut.call(path)

        expect(result).to eq('xyz456')
      end
    end

    context 'with numeric session id' do
      let(:path) { '/transcripts/123456789.jsonl' }

      it 'extracts numeric session id' do
        result = sut.call(path)

        expect(result).to eq('123456789')
      end
    end

    context 'with root level subagent' do
      let(:path) { '/session-abc/subagents/agent-test.jsonl' }

      it 'extracts parent from root level' do
        result = sut.call(path)

        expect(result).to eq('session-abc')
      end
    end
  end
end
