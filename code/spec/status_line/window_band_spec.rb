require 'tmpdir'
require_relative '../spec_helper'
require_relative '../../lib/dude/status_line/window_band'
require_relative '../../lib/dude/transcript/usage_cache_store'
require_relative '../../lib/dude/transcript/usage_cache'
require_relative '../../lib/dude/transcript/silo_registry'

describe Dude::StatusLine::WindowBand do
  include_context 'band spec setup'

  ScannerSpawner = Dude::Transcript::ScannerSpawner

  describe '#silo_list_data' do
    context 'when cache is fresh (warm)' do
      let(:session_data) { { 'session_name' => 'test_silo' } }
      let(:cache_data_content) do
        {
          files: {},
          windows: {
            '5h' => {
              start: 0,
              costs: { 'silo-1' => 30, 'silo-2' => 10 },
              seen_ids: []
            }
          }
        }
      end
      let(:transcript_mtime_delta) { 0 }
      let(:silos_config) do
        {
          'test_silo' => { 'id' => 'silo-1' },
          'other_silo' => { 'id' => 'silo-2' }
        }
      end
      let(:cache_path_to_sut) { @cache_path }
      let(:should_write_lock_file) { true }
      let(:use_manual_cache_creation) { true }

      around do |example|
        Dir.mktmpdir do |tmpdir|
          @tmpdir = tmpdir
          @cache_path = File.join(tmpdir, 'cache.json')
          @silos_path = File.join(tmpdir, 'silos.json')
          example.run
        end
      end

      before do
        silos_data = { 'silos' => silos_config }
        File.write(@silos_path, JSON.generate(silos_data))

        if transcript_mtime_delta
          transcript_file = File.join(@tmpdir, 'transcript.jsonl')
          File.write(transcript_file, '')
          cached_mtime = Time.at(1000).to_i
          actual_mtime = Time.at(1000 + transcript_mtime_delta).to_i
          File.utime(actual_mtime, actual_mtime, transcript_file)
          cache_data_content[:files] = { transcript_file => [cached_mtime, 0] }
        end

        if cache_data_content.any?
          File.write(@cache_path, JSON.generate(cache_data_content))
        end

        if should_write_lock_file
          File.write("#{@cache_path}.lock", '12345')
        end
      end

      let(:sut) do
        cache_store = Dude::Transcript::UsageCacheStore.new(@cache_path)
        registry = Dude::Transcript::SiloRegistry.new(@silos_path)
        registry.load

        if use_manual_cache_creation
          parsed_cache_data = JSON.parse(
            File.read(@cache_path),
            symbolize_names: true
          )
          cache = Dude::Transcript::UsageCache.new(SimplePriceTable.new)
          cache.from_h(parsed_cache_data)
        else
          cache = cache_store.load(SimplePriceTable.new)
        end

        sut_opts = { window: '5h', cache: cache, registry: registry }
        sut_opts[:cache_path] = cache_path_to_sut if cache_path_to_sut
        described_class.new(session_data, **sut_opts)
      end

      it 'returns array with silo_usage and silo_registry' do
        result = sut.silo_list_data
        expect(result).to be_a(Array)
        expect(result.size).to eq(2)
      end

      it 'returns silo_usage as first element' do
        result = sut.silo_list_data
        expect(result[0]).to be_a(Dude::Transcript::SiloUsage)
      end

      it 'returns silo_registry as second element' do
        result = sut.silo_list_data
        expect(result[1]).to be_a(Dude::Transcript::SiloRegistry)
      end
    end

    context 'when cache is missing' do
      let(:session_data) { { 'session_name' => 'test_silo' } }
      let(:cache_data_content) { { files: {}, windows: {} } }
      let(:transcript_mtime_delta) { nil }
      let(:silos_config) { { 'test_silo' => { 'id' => 'silo-1' } } }
      let(:cache_path_to_sut) { nil }

      around do |example|
        Dir.mktmpdir do |tmpdir|
          @tmpdir = tmpdir
          @cache_path = File.join(tmpdir, 'cache.json')
          @silos_path = File.join(tmpdir, 'silos.json')
          example.run
        end
      end

      before do
        silos_data = { 'silos' => silos_config }
        File.write(@silos_path, JSON.generate(silos_data))

        if transcript_mtime_delta
          transcript_file = File.join(@tmpdir, 'transcript.jsonl')
          File.write(transcript_file, '')
          cached_mtime = Time.at(1000).to_i
          actual_mtime = Time.at(1000 + transcript_mtime_delta).to_i
          File.utime(actual_mtime, actual_mtime, transcript_file)
          cache_data_content[:files] = { transcript_file => [cached_mtime, 0] }
        end

        if cache_data_content.any?
          File.write(@cache_path, JSON.generate(cache_data_content))
        end
      end

      let(:sut) do
        cache_store = Dude::Transcript::UsageCacheStore.new(@cache_path)
        registry = Dude::Transcript::SiloRegistry.new(@silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        sut_opts = { window: '5h', cache: cache, registry: registry }
        sut_opts[:cache_path] = cache_path_to_sut if cache_path_to_sut
        described_class.new(session_data, **sut_opts)
      end

      it 'returns nil (cache is cold)' do
        expect_any_instance_of(ScannerSpawner).to receive(:spawn)
        expect(sut.silo_list_data).to be_nil
      end
    end

    context 'when cache is stale' do
      let(:session_data) { { 'session_name' => 'test_silo' } }
      let(:cache_data_content) { { files: {}, windows: {} } }
      let(:transcript_mtime_delta) { 1000 }
      let(:silos_config) { { 'test_silo' => { 'id' => 'silo-1' } } }
      let(:cache_path_to_sut) { nil }

      around do |example|
        Dir.mktmpdir do |tmpdir|
          @tmpdir = tmpdir
          @cache_path = File.join(tmpdir, 'cache.json')
          @silos_path = File.join(tmpdir, 'silos.json')
          example.run
        end
      end

      before do
        silos_data = { 'silos' => silos_config }
        File.write(@silos_path, JSON.generate(silos_data))

        if transcript_mtime_delta
          transcript_file = File.join(@tmpdir, 'transcript.jsonl')
          File.write(transcript_file, '')
          cached_mtime = Time.at(1000).to_i
          actual_mtime = Time.at(1000 + transcript_mtime_delta).to_i
          File.utime(actual_mtime, actual_mtime, transcript_file)
          cache_data_content[:files] = { transcript_file => [cached_mtime, 0] }
        end

        if cache_data_content.any?
          File.write(@cache_path, JSON.generate(cache_data_content))
        end
      end

      let(:sut) do
        cache_store = Dude::Transcript::UsageCacheStore.new(@cache_path)
        registry = Dude::Transcript::SiloRegistry.new(@silos_path)
        registry.load
        cache = cache_store.load(SimplePriceTable.new)

        sut_opts = { window: '5h', cache: cache, registry: registry }
        sut_opts[:cache_path] = cache_path_to_sut if cache_path_to_sut
        described_class.new(session_data, **sut_opts)
      end

      it 'returns nil (cache is stale)' do
        expect_any_instance_of(ScannerSpawner).to receive(:spawn)
        expect(sut.silo_list_data).to be_nil
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

          described_class.new(
            session_data, window: '5h', cache: cache, registry: registry
          )
        end
      end

      it 'returns nil and does not raise' do
        expect(sut.silo_list_data).to be_nil
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

          described_class.new(
            session_data, window: '5h', cache: cache, registry: registry
          )
        end
      end

      it 'returns nil and does not raise' do
        expect(sut.silo_list_data).to be_nil
      end
    end
  end
end
