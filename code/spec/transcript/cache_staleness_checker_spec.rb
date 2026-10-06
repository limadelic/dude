require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/cache_staleness_checker'
require_relative '../../lib/dude/transcript/usage_cache'

describe Dude::Transcript::CacheStalenessChecker do
  include RR::DSL
  let(:sut) { described_class.new(cache_path) }

  let(:cache_path) { '/home/user/.claude/dude/usage_cache.json' }
  let(:price_table) { double(cost: 1.5) }

  describe '#stale?' do
    context 'when cache file does not exist' do
      before do
        stub(File).exist?(cache_path) { false }
      end

      it 'returns true' do
        expect(sut.stale?).to be true
      end
    end

    context 'when cache file exists but no files have been scanned' do
      before do
        stub(File).exist?(cache_path) { true }
        cache_data = { 'files' => {}, 'windows' => {} }
        stub(JSON).load_file(cache_path) { cache_data }
      end

      it 'returns false' do
        expect(sut.stale?).to be false
      end
    end

    context 'when a tracked file has changed mtime' do
      let(:file_path) { '/path/to/file.jsonl' }
      let(:old_mtime) { Time.at(1000).to_i }
      let(:new_mtime) { Time.at(2000).to_i }

      before do
        stub(File).exist?(cache_path) { true }
        cache_data = {
          'files' => { file_path => [old_mtime, 5000] },
          'windows' => {}
        }
        stub(JSON).load_file(cache_path) { cache_data }
        stub(File).stat(file_path) { double(mtime: new_mtime, size: 6000) }
      end

      it 'returns true' do
        expect(sut.stale?).to be true
      end
    end

    context 'when a tracked file has grown beyond cached offset' do
      let(:file_path) { '/path/to/file.jsonl' }
      let(:mtime) { Time.at(1000).to_i }
      let(:cached_offset) { 5000 }
      let(:new_size) { 6000 }

      before do
        stub(File).exist?(cache_path) { true }
        cache_data = {
          'files' => { file_path => [mtime, cached_offset] },
          'windows' => {}
        }
        stub(JSON).load_file(cache_path) { cache_data }
        stub(File).stat(file_path) { double(mtime: mtime, size: new_size) }
      end

      it 'returns true' do
        expect(sut.stale?).to be true
      end
    end

    context 'when all tracked files have unchanged mtime and size' do
      let(:file_path) { '/path/to/file.jsonl' }
      let(:mtime) { Time.at(1000).to_i }
      let(:offset) { 5000 }

      before do
        stub(File).exist?(cache_path) { true }
        cache_data = {
          'files' => { file_path => [mtime, offset] },
          'windows' => {}
        }
        stub(JSON).load_file(cache_path) { cache_data }
        stub(File).stat(file_path) { double(mtime: mtime, size: offset) }
      end

      it 'returns false' do
        expect(sut.stale?).to be false
      end
    end

    context 'when tracked file no longer exists' do
      let(:file_path) { '/path/to/file.jsonl' }
      let(:mtime) { Time.at(1000).to_i }

      before do
        stub(File).exist?(cache_path) { true }
        cache_data = {
          'files' => { file_path => [mtime, 5000] },
          'windows' => {}
        }
        stub(JSON).load_file(cache_path) { cache_data }
        stub(File).stat(file_path) { raise Errno::ENOENT }
      end

      it 'returns false (file is gone, cache is still valid for that file)' do
        expect(sut.stale?).to be false
      end
    end

    context 'when cache JSON is invalid' do
      before do
        stub(File).exist?(cache_path) { true }
        stub(JSON).load_file(cache_path) { raise JSON::ParserError.new('bad json') }
      end

      it 'returns true (treat corrupt cache as stale)' do
        expect(sut.stale?).to be true
      end
    end
  end
end
