require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/current_silo'

describe Dude::Transcript::CurrentSilo do
  include RR::DSL
  let(:sut) { described_class.new(registry) }

  let(:registry) { double }

  before do
    stub(registry).silo_id('dude') { 'uuid-dude' }
    stub(registry).silo_id('code') { 'uuid-code' }
    stub(registry).silo_id('dude.kent') { 'uuid-kent' }
    stub(registry).silo_id(anything) { nil }
    stub(registry).roster do
      {
        'dude' => { 'id' => 'uuid-dude' },
        'code' => { 'id' => 'uuid-code' },
        'dude.kent' => { 'id' => 'uuid-kent' }
      }
    end
  end

  describe '#call' do
    context 'when session_name matches roster name' do
      it 'returns silo id for exact match' do
        result = sut.call(session_name: 'dude')

        expect(result).to eq('uuid-dude')
      end

      it 'returns silo id for dotted name' do
        result = sut.call(session_name: 'dude.kent')

        expect(result).to eq('uuid-kent')
      end
    end

    context 'when customTitle matches roster name' do
      it 'returns silo id from customTitle' do
        result = sut.call(customTitle: 'code')

        expect(result).to eq('uuid-code')
      end
    end

    context 'when agentName matches roster name' do
      it 'returns silo id from agentName' do
        result = sut.call(agentName: 'dude')

        expect(result).to eq('uuid-dude')
      end
    end

    context 'when no field matches roster' do
      it 'returns nil for no match' do
        result = sut.call(session_name: 'unknown')

        expect(result).to be_nil
      end

      it 'returns nil when all fields provided but no match' do
        result = sut.call(
          session_name: 'unknown',
          customTitle: 'not-found',
          agentName: 'missing'
        )

        expect(result).to be_nil
      end
    end

    context 'with multiple fields provided' do
      before do
        stub(registry).silo_id('session-name') { 'uuid-session' }
        stub(registry).silo_id('agent') { 'uuid-agent' }
      end

      it 'uses session_name if it matches' do
        result = sut.call(
          session_name: 'session-name',
          customTitle: 'title',
          agentName: 'agent'
        )

        expect(result).to eq('uuid-session')
      end
    end

    context 'when session_name does not match but customTitle does' do
      before do
        stub(registry).silo_id('session-name') { nil }
        stub(registry).silo_id('title') { 'uuid-title' }
      end

      it 'uses customTitle as fallback' do
        result = sut.call(
          session_name: 'session-name',
          customTitle: 'title'
        )

        expect(result).to eq('uuid-title')
      end
    end

    context 'when agentName matches after others do not' do
      before do
        stub(registry).silo_id('session-name') { nil }
        stub(registry).silo_id('title') { nil }
        stub(registry).silo_id('agent') { 'uuid-agent' }
      end

      it 'uses agentName as final fallback' do
        result = sut.call(
          session_name: 'session-name',
          customTitle: 'title',
          agentName: 'agent'
        )

        expect(result).to eq('uuid-agent')
      end
    end

    context 'with no fields provided' do
      it 'returns nil' do
        result = sut.call

        expect(result).to be_nil
      end
    end

    context 'when only nil fields are provided' do
      it 'returns nil' do
        result = sut.call(session_name: nil, customTitle: nil, agentName: nil)

        expect(result).to be_nil
      end
    end

    context 'with fork notation in session_name' do
      before do
        stub(registry).silo_id('code ⑂ feature') { 'uuid-fork' }
      end

      it 'matches fork notation' do
        result = sut.call(session_name: 'code ⑂ feature')

        expect(result).to eq('uuid-fork')
      end
    end

    context 'when silo_id method returns nil' do
      before do
        stub(registry).silo_id('unknown') { nil }
      end

      it 'returns nil for not found' do
        result = sut.call(session_name: 'unknown')

        expect(result).to be_nil
      end
    end
  end
end
