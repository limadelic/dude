require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/sun_band'

describe Dude::StatusLine::SunBand do
  include RR::DSL

  let(:sut) { described_class.new(session_data) }
  let(:session_data) { {} }

  before do
    stub(Dude::Transcript::UsageCacheStore).new { cache_store }
    stub(cache_store).load { usage_cache }
    stub(Dude::Transcript::SiloRegistry).new { registry }
    stub(Dude::Transcript::CurrentSilo).new { current_silo_instance }
    stub(Dude::Transcript::SiloUsage).new { silo_usage_instance }
  end

  let(:current_silo_instance) { double }
  let(:silo_usage_instance) { double }

  context 'when no session_name, customTitle, or agentName' do
    let(:session_data) { {} }
    let(:usage_cache) { double(instance_variable_get: {}) }
    let(:registry) do
      double(load: nil, roster: {})
    end
    let(:cache_store) { double }

    before do
      stub(current_silo_instance).call { nil }
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'with yellow band (ratio 2.0-2.9)' do
    let(:session_data) do
      { 'session_name' => 'test_silo' }
    end
    let(:registry) do
      double(
        load: nil, roster: {
          'test_silo' => { 'id' => 'silo-1' },
          'other_silo' => { 'id' => 'silo-2' }
        }
      )
    end
    let(:usage_cache) do
      double(
        instance_variable_get: {
          '5h' => {
            start: 0,
            costs: { 'silo-1' => 20, 'silo-2' => 10 },
            seen_ids: Set.new
          }
        }
      )
    end
    let(:cache_store) { double }

    before do
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 2 }
      stub(silo_usage_instance).ratio('silo-1') { 2.0 }
    end

    it 'returns :yellow' do
      expect(sut.call).to eq(:yellow)
    end
  end

  context 'with red band (ratio >= 3.0)' do
    let(:session_data) do
      { 'session_name' => 'test_silo' }
    end
    let(:registry) do
      double(
        load: nil, roster: {
          'test_silo' => { 'id' => 'silo-1' },
          'other_silo' => { 'id' => 'silo-2' }
        }
      )
    end
    let(:usage_cache) do
      double(
        instance_variable_get: {
          '5h' => {
            start: 0,
            costs: { 'silo-1' => 60, 'silo-2' => 20 },
            seen_ids: Set.new
          }
        }
      )
    end
    let(:cache_store) { double }

    before do
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 2 }
      stub(silo_usage_instance).ratio('silo-1') { 3.0 }
    end

    it 'returns :red' do
      expect(sut.call).to eq(:red)
    end
  end

  context 'when only 1 active silo' do
    let(:session_data) do
      { 'session_name' => 'test_silo' }
    end
    let(:registry) do
      double(
        load: nil, roster: {
          'test_silo' => { 'id' => 'silo-1' }
        }
      )
    end
    let(:usage_cache) do
      double(
        instance_variable_get: {
          '5h' => {
            start: 0,
            costs: { 'silo-1' => 10 },
            seen_ids: Set.new
          }
        }
      )
    end
    let(:cache_store) { double }

    before do
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 1 }
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'when 0 active silos' do
    let(:session_data) do
      { 'session_name' => 'test_silo' }
    end
    let(:registry) do
      double(
        load: nil, roster: {
          'test_silo' => { 'id' => 'silo-1' }
        }
      )
    end
    let(:usage_cache) do
      double(
        instance_variable_get: {
          '5h' => {
            start: 0,
            costs: {},
            seen_ids: Set.new
          }
        }
      )
    end
    let(:cache_store) { double }

    before do
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 0 }
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'when cache file is missing' do
    let(:session_data) do
      { 'session_name' => 'test_silo' }
    end
    let(:registry) do
      double(
        load: nil, roster: {
          'test_silo' => { 'id' => 'silo-1' }
        }
      )
    end
    let(:usage_cache) do
      double(instance_variable_get: {})
    end
    let(:cache_store) { double }

    before do
      stub(current_silo_instance).call { 'silo-1' }
      stub(silo_usage_instance).active_count { 0 }
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when cache file is corrupt' do
    let(:session_data) do
      { 'session_name' => 'test_silo' }
    end
    let(:registry) do
      double(
        load: nil, roster: {
          'test_silo' => { 'id' => 'silo-1' }
        }
      )
    end
    let(:usage_cache) do
      double
    end
    let(:cache_store) { double }

    before do
      stub(current_silo_instance).call { 'silo-1' }
      stub(usage_cache).instance_variable_get(:@windows) { raise StandardError }
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when silos.json is missing' do
    let(:session_data) do
      { 'session_name' => 'test_silo' }
    end
    let(:registry) do
      double(load: nil, roster: {})
    end
    let(:usage_cache) do
      double(instance_variable_get: {})
    end
    let(:cache_store) { double }

    before do
      stub(current_silo_instance).call { nil }
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when silos.json is corrupt' do
    let(:session_data) do
      { 'session_name' => 'test_silo' }
    end
    let(:registry) do
      double
    end
    let(:usage_cache) do
      double(instance_variable_get: {})
    end
    let(:cache_store) { double }

    before do
      stub(registry).load { raise StandardError }
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end
end
