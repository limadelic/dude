require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/process_manager"

describe Dude::Dudes::ProcessManager do
  include RR::DSL

  describe '.kill_watchers' do
    it 'kills all dude abide processes' do
      stub(described_class).pgrep_all('dude abide') { [123, 456] }
      mock(described_class).kill_process(123)
      mock(described_class).kill_process(456)

      described_class.kill_watchers
    end
  end

  describe '.pgrep_all' do
    it 'returns array of pids matching pattern' do
      stub(described_class).`.with('pgrep -f "dude abide"') { "123\n456\n789" }

      expect(described_class.pgrep_all('dude abide'))
        .to eq([123, 456, 789])
    end

    it 'filters out non-positive integers' do
      stub(described_class).`.with('pgrep -f "dude abide"') { "123\n0\n-1\n456" }

      expect(described_class.pgrep_all('dude abide'))
        .to eq([123, 456])
    end

    it 'returns empty array when no matches' do
      stub(described_class).`.with('pgrep -f "dude abide"') { "" }

      expect(described_class.pgrep_all('dude abide'))
        .to eq([])
    end
  end

  describe '.kill_process' do
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
