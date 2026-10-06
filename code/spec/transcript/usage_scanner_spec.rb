require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/usage_scanner'

describe Dude::Transcript::UsageScanner do
  include RR::DSL
  let(:sut) { described_class.new }

  let(:cache) { double }
  let(:file_path) { '/path/to/transcript.jsonl' }
  let(:session_id) { 'sess-123' }
  let(:windows) { %w[5h week] }

  let(:line_1) do
    ts = '2025-01-01T10:00:00Z'
    id_msg = 'msg-1'
    tokens = 100
    build_json_line(ts, id_msg, tokens, session_id)
  end
  let(:line_2) do
    ts = '2025-01-02T10:00:00Z'
    id_msg = 'msg-2'
    tokens = 200
    build_json_line(ts, id_msg, tokens, session_id)
  end

  def build_json_line(timestamp, message_id, tokens, session_id_val)
    "{\"timestamp\":\"#{timestamp}\",\"message\":{\"id\":\"#{message_id}\"," \
      "\"model\":\"claude-opus-5\",\"usage\":{\"input_tokens\":#{tokens}}}," \
      "\"sessionId\":\"#{session_id_val}\"}"
  end

  let(:parsed_record_1) do
    {
      id: 'msg-1',
      model: 'claude-opus-5',
      usage: { 'input_tokens' => 100 },
      epoch: 1735737600,
      session: session_id
    }
  end

  let(:parsed_record_2) do
    {
      id: 'msg-2',
      model: 'claude-opus-5',
      usage: { 'input_tokens' => 200 },
      epoch: 1735824000,
      session: session_id
    }
  end

  let(:current_mtime) { 1000 }
  let(:file_content) { line_1 + "\n" + line_2 + "\n" }
  let(:file_size) { file_content.bytesize }

  before do
    transcript_usage = double
    stub(transcript_usage).parse(line_1) { parsed_record_1 }
    stub(transcript_usage).parse(line_2) { parsed_record_2 }
    stub(Dude::Transcript::TranscriptUsage).new { transcript_usage }

    session_extractor = double
    stub(session_extractor).call(file_path) { session_id }
    stub(Dude::Transcript::SessionIdExtractor).new { session_extractor }

    file_obj = double
    stub(file_obj).read { file_content }
    stub(file_obj).close { nil }
    stub(File).open(file_path, 'r') { file_obj }
    stub(File).stat(file_path) do
      double(mtime: current_mtime, size: file_size)
    end

    stub(cache).file_state { nil }
    stub(cache).set_file_state { nil }
    mock(cache).add('5h', parsed_record_1)
    mock(cache).add('week', parsed_record_1)
    mock(cache).add('5h', parsed_record_2)
    mock(cache).add('week', parsed_record_2)
  end

  describe '#scan' do
    context 'when file has no cached state' do
      before do
        stub(cache).file_state(file_path) { nil }
      end

      it 'reads and parses lines from file' do
        sut.scan(cache, [file_path], windows)
      end

      it 'stores file state after processing' do
        mock(cache).set_file_state(file_path, current_mtime, file_size)
        sut.scan(cache, [file_path], windows)
      end
    end

    context 'when file mtime has not changed' do
      let(:cached_mtime) { current_mtime }
      let(:cached_offset) { 100 }

      before do
        stub(cache).file_state { [cached_mtime, cached_offset] }
      end

      it 'skips file' do
        dont_allow(cache).add
        sut.scan(cache, [file_path], windows)
      end
    end

    context 'when file mtime has changed' do
      let(:cached_mtime) { 900 }
      let(:cached_offset) { 100 }

      before do
        stub(cache).file_state { [cached_mtime, cached_offset] }
        file_obj = double
        stub(file_obj).read(cached_offset) { '' }
        stub(file_obj).read { file_content }
        stub(file_obj).close { nil }
        stub(File).open(file_path, 'r') { file_obj }
      end

      it 'reads from cached offset' do
        sut.scan(cache, [file_path], windows)
      end
    end

    context 'when file becomes smaller than cached offset' do
      let(:cached_mtime) { 900 }
      let(:cached_offset) { 5000 }

      before do
        stub(cache).file_state { [cached_mtime, cached_offset] }
      end

      it 'starts from beginning' do
        file_obj = double
        stub(file_obj).read { file_content }
        stub(file_obj).close { nil }
        stub(File).open(file_path, 'r') { file_obj }
        sut.scan(cache, [file_path], windows)
      end

      it 'stores reset offset' do
        file_obj = double
        stub(file_obj).read { file_content }
        stub(file_obj).close { nil }
        stub(File).open(file_path, 'r') { file_obj }
        mock(cache).set_file_state(file_path, current_mtime, file_size)
        sut.scan(cache, [file_path], windows)
      end
    end

    context 'when parse returns nil' do
      before do
        stub(cache).file_state { nil }
        transcript_usage = double
        stub(transcript_usage).parse(line_1) { nil }
        stub(transcript_usage).parse(line_2) { nil }
        stub(Dude::Transcript::TranscriptUsage).new { transcript_usage }
        dont_allow(cache).add
      end

      it 'skips nil records' do
        sut.scan(cache, [file_path], windows)
      end
    end

    context 'with multiple files' do
      let(:file_path_2) { '/path/to/other.jsonl' }
      let(:session_id_2) { 'sess-456' }

      before do
        stub(File).stat(file_path_2) do
          double(mtime: current_mtime + 1, size: 500)
        end
        file_obj_2 = double
        stub(file_obj_2).read { line_1 + "\n" }
        stub(file_obj_2).close { nil }
        stub(File).open(file_path_2, 'r') { file_obj_2 }

        session_extractor = double
        stub(session_extractor).call(file_path) { session_id }
        stub(session_extractor).call(file_path_2) { session_id_2 }
        stub(Dude::Transcript::SessionIdExtractor).new { session_extractor }

        stub(cache).add { nil }
      end

      it 'processes all files' do
        sut.scan(cache, [file_path, file_path_2], windows)
      end
    end

    context 'with incomplete line at end of file' do
      let(:partial_content) { line_1 + "\n" + line_2 }

      before do
        stub(cache).file_state { nil }
        stub(File).stat(file_path) do
          double(mtime: current_mtime, size: partial_content.bytesize)
        end
        file_obj = double
        stub(file_obj).read { partial_content }
        stub(file_obj).close { nil }
        stub(File).open(file_path, 'r') { file_obj }
      end

      it 'skips incomplete lines' do
        dont_allow(cache).add.with('5h', parsed_record_2)
        dont_allow(cache).add.with('week', parsed_record_2)
        sut.scan(cache, [file_path], windows)
      end

      it 'stores offset at last complete newline' do
        complete_offset = line_1.bytesize + 1
        mock(cache).set_file_state(file_path, current_mtime, complete_offset)
        sut.scan(cache, [file_path], windows)
      end
    end
  end
end
