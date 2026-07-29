require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/models'
require_relative '../../lib/dude/transcript/request_counter'
require_relative '../examples/shared'

describe Dude::StatusLine::Models do
  include RR::DSL

  describe 'to_s' do
    let :request_counter do
      Object.new
    end

    let :transcript_path do
      '/path/to/transcript.jsonl'
    end

    let :session do
      {
        'model' => { 'id' => 'claude-opus-4-8' },
        'transcript_path' => transcript_path
      }
    end

    let :sut do
      Dude::StatusLine::Models.new(session, {})
    end

    before do
      stub(Dude::Transcript::RequestCounter).new { request_counter }
      stub(request_counter).count(transcript_path) { counts }
    end

    context 'with usage across multiple models sorted descending' do
      let :counts do
        { 'haiku' => 47, 'opus' => 12, 'sonnet' => 41 }
      end

      it 'renders each model emoji repeated by percentage divided by 10' do
        result = strip(sut.to_s)
        haiku_count = result.count('🐸')
        sonnet_count = result.count('🎸')
        opus_count = result.count('🎭')
        expect(haiku_count).to eq(5)
        expect(sonnet_count).to eq(4)
        expect(opus_count).to eq(1)
      end

      it 'sorts by request count descending' do
        result = strip(sut.to_s)
        haiku_pos = result.index('🐸')
        sonnet_pos = result.index('🎸')
        opus_pos = result.index('🎭')
        expect(haiku_pos).to be < sonnet_pos
        expect(sonnet_pos).to be < opus_pos
      end

      it 'highlights current model with emoji_group' do
        result = sut.to_s
        expect(result).to include("\033[42m")
      end

      it 'uses neutral green color' do
        result = sut.to_s
        expect(result).to include("\033[32m")
      end
    end

    context 'with only one model in use' do
      let :counts do
        { 'haiku' => 100 }
      end

      it 'renders single model bar' do
        result = strip(sut.to_s)
        expect(result).to eq('🐸' * 10)
      end
    end

    context 'with models having zero requests' do
      let :counts do
        { 'haiku' => 50, 'opus' => 50 }
      end

      it 'excludes models with zero requests' do
        result = strip(sut.to_s)
        expect(result).not_to include('🎸')
        expect(result).not_to include('🦄')
      end
    end

    context 'with no transcript path in session' do
      let :session do
        { 'model' => { 'id' => 'claude-opus-4-8' } }
      end

      it 'returns empty string' do
        expect(sut.to_s).to eq('')
      end
    end

    context 'with empty counts' do
      let :counts do
        {}
      end

      it 'returns empty string' do
        expect(sut.to_s).to eq('')
      end
    end

    context 'when request counter raises error' do
      before do
        stub(request_counter).count(transcript_path) { raise StandardError }
      end

      it 'returns empty string without raising' do
        expect(sut.to_s).to eq('')
      end
    end

    context 'with rounding at percentage boundary' do
      let :counts do
        { 'haiku' => 49, 'opus' => 51 }
      end

      it 'rounds percentage division by 10 correctly' do
        result = strip(sut.to_s)
        haiku_count = result.count('🐸')
        opus_count = result.count('🎭')
        expect(haiku_count).to eq(5)
        expect(opus_count).to eq(5)
      end
    end
  end
end
