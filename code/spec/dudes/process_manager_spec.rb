require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/process_manager"

describe Dude::Dudes::ProcessManager do
  describe '.kill_watchers' do
    it 'kills all dude abide processes' do
      allow(described_class).to receive(:pgrep_all).and_return([123, 456])
      allow(described_class).to receive(:kill_process)

      described_class.kill_watchers

      expect(described_class).to have_received(:pgrep_all).with('dude abide')
    end

    it 'calls kill_process for each pid' do
      allow(described_class).to receive(:pgrep_all).and_return([123, 456])
      allow(described_class).to receive(:kill_process)

      described_class.kill_watchers

      expect(described_class).to have_received(:kill_process).with(123)
      expect(described_class).to have_received(:kill_process).with(456)
    end
  end

  describe '.pgrep_all' do
    it 'returns array of pids matching pattern' do
      allow_any_instance_of(Kernel).to receive(:`).and_return("123\n456\n789")

      result = described_class.pgrep_all('dude abide')

      expect(result).to eq([123, 456, 789])
    end

    it 'filters out non-positive integers' do
      allow_any_instance_of(Kernel).to receive(:`).and_return("123\n0\n-1\n456")

      result = described_class.pgrep_all('dude abide')

      expect(result).to eq([123, 456])
    end

    it 'returns empty array when no matches' do
      allow_any_instance_of(Kernel).to receive(:`).and_return("")

      result = described_class.pgrep_all('dude abide')

      expect(result).to eq([])
    end
  end

  describe '.kill_process' do
    it 'sends TERM signal to process' do
      allow(Process).to receive(:kill)

      described_class.kill_process(123)

      expect(Process).to have_received(:kill).with('TERM', 123)
    end

    it 'gracefully handles missing process' do
      allow(Process).to receive(:kill).and_raise(Errno::ESRCH)

      expect { described_class.kill_process(999) }.not_to raise_error
    end
  end
end
