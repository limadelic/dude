require 'tmpdir'
require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/sun_band'
require_relative '../../lib/dude/transcript/usage_cache_store'
require_relative '../../lib/dude/transcript/usage_cache'
require_relative '../../lib/dude/transcript/silo_registry'

class SimplePriceTable
  def cost(model, usage)
    1.5
  end
end

describe Dude::StatusLine::SunBand do
  let(:session_data) { {} }

  context 'when no session_name, customTitle, or agentName' do
    let(:session_data) { {} }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        cache_data = {
          files: {},
          windows: {}
        }
        File.write(cache_path, JSON.generate(cache_data))

        silos_data = {
          'silos' => {}
        }
        File.write(silos_path, JSON.generate(silos_data))

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'with yellow band (ratio 2.0-2.9)' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        cache_data = {
          files: {},
          windows: {
            '5h' => {
              start: 0,
              costs: {
                'silo-1' => 30,
                'silo-2' => 10,
                'silo-3' => 5
              },
              seen_ids: []
            }
          }
        }
        json_str = JSON.generate(cache_data)
        File.write(cache_path, json_str)

        silos_data = {
          'silos' => {
            'test_silo' => { 'id' => 'silo-1' },
            'other_silo' => { 'id' => 'silo-2' },
            'third_silo' => { 'id' => 'silo-3' }
          }
        }
        File.write(silos_path, JSON.generate(silos_data))

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load

        parsed_cache_data = JSON.parse(json_str, symbolize_names: true)
        cache = Dude::Transcript::UsageCache.new(SimplePriceTable.new)
        cache.from_h(parsed_cache_data)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns :yellow' do
      expect(sut.call).to eq(:yellow)
    end
  end

  context 'with red band (ratio >= 3.0)' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        cache_data = {
          files: {},
          windows: {
            '5h' => {
              start: 0,
              costs: {
                'silo-1' => 90,
                'silo-2' => 10,
                'silo-3' => 10,
                'silo-4' => 10
              },
              seen_ids: []
            }
          }
        }
        json_str = JSON.generate(cache_data)
        File.write(cache_path, json_str)

        silos_data = {
          'silos' => {
            'test_silo' => { 'id' => 'silo-1' },
            'other_silo' => { 'id' => 'silo-2' },
            'third_silo' => { 'id' => 'silo-3' },
            'fourth_silo' => { 'id' => 'silo-4' }
          }
        }
        File.write(silos_path, JSON.generate(silos_data))

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load

        parsed_cache_data = JSON.parse(json_str, symbolize_names: true)
        cache = Dude::Transcript::UsageCache.new(SimplePriceTable.new)
        cache.from_h(parsed_cache_data)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns :red' do
      expect(sut.call).to eq(:red)
    end
  end

  context 'when only 1 active silo' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        cache_data = {
          files: {},
          windows: {
            '5h' => {
              start: 0,
              costs: { 'silo-1' => 10 },
              seen_ids: []
            }
          }
        }
        File.write(cache_path, JSON.generate(cache_data))

        silos_data = {
          'silos' => {
            'test_silo' => { 'id' => 'silo-1' }
          }
        }
        File.write(silos_path, JSON.generate(silos_data))

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'when 0 active silos' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        cache_data = {
          files: {},
          windows: {
            '5h' => {
              start: 0,
              costs: {},
              seen_ids: []
            }
          }
        }
        File.write(cache_path, JSON.generate(cache_data))

        silos_data = {
          'silos' => {
            'test_silo' => { 'id' => 'silo-1' }
          }
        }
        File.write(silos_path, JSON.generate(silos_data))

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns nil' do
      expect(sut.call).to be_nil
    end
  end

  context 'when cache file is missing' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        silos_data = {
          'silos' => {
            'test_silo' => { 'id' => 'silo-1' }
          }
        }
        File.write(silos_path, JSON.generate(silos_data))

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when cache file is corrupt' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        File.write(cache_path, 'invalid json {')

        silos_data = {
          'silos' => {
            'test_silo' => { 'id' => 'silo-1' }
          }
        }
        File.write(silos_path, JSON.generate(silos_data))

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when silos.json is missing' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        cache_data = {
          files: {},
          windows: {}
        }
        File.write(cache_path, JSON.generate(cache_data))

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end

  context 'when silos.json is corrupt' do
    let(:session_data) { { 'session_name' => 'test_silo' } }
    let(:sut) do
      Dir.mktmpdir do |tmpdir|
        cache_path = File.join(tmpdir, 'cache.json')
        silos_path = File.join(tmpdir, 'silos.json')

        cache_data = {
          files: {},
          windows: {}
        }
        File.write(cache_path, JSON.generate(cache_data))

        File.write(silos_path, 'invalid json {')

        cache_store = Dude::Transcript::UsageCacheStore.new(cache_path)
        registry = Dude::Transcript::SiloRegistry.new(silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        described_class.new(session_data, cache: cache, registry: registry)
      end
    end

    it 'returns nil and does not raise' do
      expect(sut.call).to be_nil
    end
  end
end
