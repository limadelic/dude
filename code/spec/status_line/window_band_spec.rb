require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/window_band'

describe Dude::StatusLine::WindowBand do
  include RR::DSL

  let(:sut) do
    described_class.new(
      session_data,
      window: '5h',
      cache: cache,
      registry: registry,
      cache_path: cache_path
    )
  end

  let(:session_data) { { 'session_name' => 'test_session' } }
  let(:cache) { Object.new }
  let(:registry) { Object.new }
  let(:cache_path) { '/tmp/cache.json' }

  describe '#silo_list_data' do
    let(:silo_usage_double) { Object.new }
    let(:registry_double) { Object.new }

    before do
      stub(sut).cache_is_stale? { cache_is_stale }
      stub(sut).silo_usage { silo_usage_double }
      stub(sut).silo_registry { registry_double }
    end

    context 'when cache is warm' do
      let(:cache_is_stale) { false }

      it 'returns array with silo_usage and registry' do
        result = sut.silo_list_data
        expect(result).to eq([silo_usage_double, registry_double])
      end
    end

    context 'when cache is cold or stale' do
      let(:cache_is_stale) { true }

      it 'returns nil' do
        expect(sut.silo_list_data).to be_nil
      end
    end

    context 'when error occurs' do
      let(:cache_is_stale) { raise StandardError, 'cache check failed' }

      it 'returns nil' do
        expect(sut.silo_list_data).to be_nil
      end
    end
  end
end
