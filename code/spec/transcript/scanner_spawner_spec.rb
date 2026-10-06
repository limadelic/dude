require_relative '../spec_helper'
require_relative '../../lib/dude/transcript/scanner_spawner'

describe Dude::Transcript::ScannerSpawner do
  include RR::DSL
  let(:sut) { described_class.new(cache_path) }

  let(:cache_path) { '/home/user/.claude/dude/usage_cache.json' }
  let(:lock_path) { "#{cache_path}.lock" }
  let(:scanner_pid) { 12345 }

  describe '#spawn' do
    context 'when no scan is currently running' do
      before do
        stub(File).exist?(lock_path) { false }
        stub(Process).spawn(
          'dude', 'transcript', 'scan',
          out: File::NULL, err: File::NULL
        ) { scanner_pid }
        stub(Process).detach(scanner_pid)
        stub(File).write(lock_path, scanner_pid.to_s)
      end

      it 'spawns the scanner in background' do
        mock(Process).spawn(
          'dude', 'transcript', 'scan',
          out: File::NULL, err: File::NULL
        )

        sut.spawn
      end

      it 'detaches the spawned process' do
        stub(Process).spawn(
          'dude', 'transcript', 'scan',
          out: File::NULL, err: File::NULL
        ) { scanner_pid }
        mock(Process).detach(scanner_pid)

        sut.spawn
      end

      it 'writes lock file with scanner pid' do
        stub(Process).spawn(
          'dude', 'transcript', 'scan',
          out: File::NULL, err: File::NULL
        ) { scanner_pid }
        stub(Process).detach(scanner_pid)
        mock(File).write(lock_path, scanner_pid.to_s)

        sut.spawn
      end

      it 'returns true indicating spawn happened' do
        stub(Process).spawn(
          'dude', 'transcript', 'scan',
          out: File::NULL, err: File::NULL
        ) { scanner_pid }
        stub(Process).detach(scanner_pid)
        stub(File).write(lock_path, scanner_pid.to_s)

        expect(sut.spawn).to be true
      end
    end

    context 'when a scan is already running (lock file exists)' do
      before do
        stub(File).exist?(lock_path) { true }
      end

      it 'does not spawn another process' do
        dont_allow(Process).spawn

        sut.spawn
      end

      it 'returns false indicating no spawn' do
        expect(sut.spawn).to be false
      end
    end

    context 'when spawn fails with an error' do
      before do
        stub(File).exist?(lock_path) { false }
        stub(Process).spawn(
          'dude', 'transcript', 'scan',
          out: File::NULL, err: File::NULL
        ) {
          raise StandardError.new('spawn failed')
        }
      end

      it 'raises no error (scan error must never break the status line)' do
        expect { sut.spawn }.not_to raise_error
      end

      it 'returns false' do
        expect(sut.spawn).to be false
      end
    end

    context 'when detach fails with an error' do
      before do
        stub(File).exist?(lock_path) { false }
        stub(Process).spawn(
          'dude', 'transcript', 'scan',
          out: File::NULL, err: File::NULL
        ) { scanner_pid }
        stub(Process).detach(scanner_pid) {
          raise StandardError.new('detach failed')
        }
      end

      it 'raises no error' do
        expect { sut.spawn }.not_to raise_error
      end

      it 'returns false' do
        expect(sut.spawn).to be false
      end
    end
  end
end
