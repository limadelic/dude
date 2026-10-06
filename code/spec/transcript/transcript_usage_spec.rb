require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/transcript_usage'

describe Dude::Transcript::TranscriptUsage do
  include RR::DSL

  let(:sut) { described_class.new }

  let(:fixture_line) do
    '{"timestamp":"2025-10-06T10:30:45Z","sessionId":"sess-123",' \
    '"message":{"id":"msg-1","model":"claude-opus-5",' \
    '"usage":{"input_tokens":100,"output_tokens":50}}}'
  end

  let(:line_without_usage) do
    '{"timestamp":"2025-10-06T10:30:45Z","sessionId":"sess-123",' \
    '"message":{"id":"msg-1","model":"claude-opus-5"}}'
  end

  let(:invalid_json) { 'not json' }

  let(:line_without_timestamp) do
    '{"sessionId":"sess-123",' \
    '"message":{"id":"msg-1","model":"claude-opus-5",' \
    '"usage":{"input_tokens":100,"output_tokens":50}}}'
  end

  let(:line_with_bad_timestamp) do
    '{"timestamp":"not-a-timestamp","sessionId":"sess-123",' \
    '"message":{"id":"msg-1","model":"claude-opus-5",' \
    '"usage":{"input_tokens":100,"output_tokens":50}}}'
  end

  describe '#parse' do
    it 'returns hash with usage, model, id, epoch, and session' do
      result = sut.parse(fixture_line)

      expect(result[:id]).to eq('msg-1')
      expect(result[:model]).to eq('claude-opus-5')
      expect(result[:usage]).to eq(
        { 'input_tokens' => 100, 'output_tokens' => 50 }
      )
      expect(result[:epoch]).to be_a(Integer)
      expect(result[:session]).to eq('sess-123')
    end

    it 'calculates correct epoch from timestamp' do
      result = sut.parse(fixture_line)

      epoch = Time.iso8601('2025-10-06T10:30:45Z').to_i
      expect(result[:epoch]).to eq(epoch)
    end

    it 'returns nil for line without message.usage' do
      result = sut.parse(line_without_usage)

      expect(result).to be_nil
    end

    it 'returns nil for invalid JSON' do
      result = sut.parse(invalid_json)

      expect(result).to be_nil
    end

    it 'returns nil for missing timestamp' do
      result = sut.parse(line_without_timestamp)

      expect(result).to be_nil
    end

    it 'returns nil for bad timestamp' do
      result = sut.parse(line_with_bad_timestamp)

      expect(result).to be_nil
    end
  end
end
