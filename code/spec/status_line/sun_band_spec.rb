require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/sun_band'

describe Dude::StatusLine::SunBand do
  include RR::DSL

  let(:session_data) { {} }

  def make_cache_double(data)
    double(instance_variable_get: data)
  end

  def make_registry_double(roster)
    double(roster: roster)
  end

  let(:current_silo_instance) { double }
  let(:silo_usage_instance) { double }

  context 'when no session_name, customTitle, or agentName' do
    let(:session_data) { {} }
    let(:sut) do
      cache = make_cache_double({})
      registry = make_registry_double({})
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { nil }
      described_class.new(session_data, cache: cache, registry: registry)
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'with yellow band (ratio 2.0-2.9)' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      cache = make_cache_double(
        {
          '5h' => {
            start: 0,
            costs: {
              'silo-1' => 20,
              'silo-2' => 10
            }
          }
        }
      )
      registry = make_registry_double(
        {
          'test_silo' => { 'id' => 'silo-1' },
          'other_silo' => { 'id' => 'silo-2' }
        }
      )
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 2 }
      stub(silo_usage_instance).ratio('silo-1') { 2.0 }
      described_class.new(session_data, cache: cache, registry: registry)
    end

    it 'returns :yellow' do
      expect(sut.call).to eq(:yellow)
    end
  end

  context 'with red band (ratio >= 3.0)' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      cache = make_cache_double(
        {
          '5h' => {
            start: 0,
            costs: {
              'silo-1' => 60,
              'silo-2' => 20
            }
          }
        }
      )
      registry = make_registry_double(
        {
          'test_silo' => { 'id' => 'silo-1' },
          'other_silo' => { 'id' => 'silo-2' }
        }
      )
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 2 }
      stub(silo_usage_instance).ratio('silo-1') { 3.0 }
      described_class.new(session_data, cache: cache, registry: registry)
    end

    it 'returns :red' do
      expect(sut.call).to eq(:red)
    end
  end

  context 'when only 1 active silo' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      cache = make_cache_double(
        {
          '5h' => {
            start: 0,
            costs: { 'silo-1' => 10 }
          }
        }
      )
      registry = make_registry_double({ 'test_silo' => { 'id' => 'silo-1' } })
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 1 }
      described_class.new(session_data, cache: cache, registry: registry)
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'when 0 active silos' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      cache = make_cache_double({ '5h' => { start: 0, costs: {} } })
      registry = make_registry_double({ 'test_silo' => { 'id' => 'silo-1' } })
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 0 }
      described_class.new(session_data, cache: cache, registry: registry)
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'when cache file is missing' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      cache = make_cache_double({})
      registry = make_registry_double({ 'test_silo' => { 'id' => 'silo-1' } })
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 0 }
      described_class.new(session_data, cache: cache, registry: registry)
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when cache file is corrupt' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      corrupt_cache = double
      registry = make_registry_double({ 'test_silo' => { 'id' => 'silo-1' } })
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { 'silo-1' }
      stub(corrupt_cache).instance_variable_get(:@windows) {
        raise StandardError
      }
      described_class.new(
        session_data, cache: corrupt_cache,
        registry: registry
      )
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when silos.json is missing' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      cache = make_cache_double({})
      registry = make_registry_double({})
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { nil }
      described_class.new(session_data, cache: cache, registry: registry)
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when silos.json is corrupt' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      cache = make_cache_double({})
      corrupt_registry = double(roster: {})
      stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
      stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
      stub(current_silo_instance).call { raise StandardError }
      described_class.new(
        session_data, cache: cache,
        registry: corrupt_registry
      )
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end
end
