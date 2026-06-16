require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/models'
require_relative '../examples/shared'

describe Dude::StatusLine::Models do
  describe 'to_s' do
    context 'when using opus' do
      let(:session) { { 'model' => { 'id' => 'claude-opus-4-8' } } }
      let(:sut) { Dude::StatusLine::Models.new(session, {}) }

      it 'returns opus emoji' do
        expect(sut.to_s).to eq('🎭')
      end
    end

    context 'when using sonnet' do
      let(:session) { { 'model' => { 'id' => 'claude-sonnet-4-5' } } }
      let(:sut) { Dude::StatusLine::Models.new(session, {}) }

      it 'returns sonnet emoji' do
        expect(sut.to_s).to eq('🎸')
      end
    end

    context 'when using haiku' do
      let(:session) { { 'model' => { 'id' => 'claude-haiku-4-5' } } }
      let(:sut) { Dude::StatusLine::Models.new(session, {}) }

      it 'returns haiku emoji' do
        expect(sut.to_s).to eq('🐸')
      end
    end

    context 'when model id is not recognized' do
      let(:session) { { 'model' => { 'id' => 'unknown-model' } } }
      let(:sut) { Dude::StatusLine::Models.new(session, {}) }

      it 'returns empty string' do
        expect(sut.to_s).to eq('')
      end
    end

    context 'when no model is provided' do
      let(:session) { {} }
      let(:sut) { Dude::StatusLine::Models.new(session, {}) }

      it 'returns empty string' do
        expect(sut.to_s).to eq('')
      end
    end
  end
end
