require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/process_manager"

describe Dude::Dudes::ProcessManager do
  include RR::DSL

  describe '.kill_watchers' do
    before do
      stub(described_class).pgrep_all { [123, 456] }
    end

    it 'kills all dude abide processes' do
      mock(described_class).kill_process(123)
      mock(described_class).kill_process(456)

      described_class.kill_watchers
    end
  end

  describe '.pgrep_all' do
    before do
      stub(described_class).` { "123\n456\n789" }
    end

    it 'returns array of pids matching pattern' do
      expect(described_class.pgrep_all('dude abide'))
        .to eq([123, 456, 789])
    end

    it 'filters out non-positive integers' do
      stub(described_class).` { "123\n0\n-1\n456" }

      expect(described_class.pgrep_all('dude abide'))
        .to eq([123, 456])
    end

    it 'returns empty array when no matches' do
      stub(described_class).` { "" }

      expect(described_class.pgrep_all('dude abide'))
        .to eq([])
    end
  end

  describe '.kill_process' do
    before do
      stub(Process).kill { nil }
    end

    it 'sends TERM signal to process' do
      mock(Process).kill('TERM', 123)

      described_class.kill_process(123)
    end

    it 'gracefully handles missing process' do
      stub(Process).kill('TERM', 999) { raise Errno::ESRCH }

      expect { described_class.kill_process(999) }
        .not_to raise_error
    end
  end
end
