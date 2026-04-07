require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/process_tree"

describe Dude::Dudes::ProcessTree do
  describe '.is_current?' do
    it 'delegates to instance method' do
      allow(Process).to receive(:ppid).and_return(200)
      allow_any_instance_of(described_class).to(
        receive(:shell_parent_pid).and_return(100, 1)
      )
      expect(described_class.is_current?(100)).to be true
    end
  end

  describe '#is_current?' do
    before do
      allow(File).to receive(:exist?).and_return(false)
      allow_any_instance_of(described_class).to receive(:shell_parent_pid)
    end

    it 'returns true when pid is in ancestor chain' do
      allow(Process).to receive(:ppid).and_return(200)
      allow_any_instance_of(described_class).to(
        receive(:shell_parent_pid).and_return(100, 1)
      )
      expect(subject.is_current?(100)).to be true
    end

    it 'returns false when pid not in ancestor chain' do
      allow(Process).to receive(:ppid).and_return(200)
      allow_any_instance_of(described_class).to(
        receive(:shell_parent_pid).and_return(999, 1)
      )
      expect(subject.is_current?(100)).to be false
    end

    it 'returns false when pid is nil' do
      expect(subject.is_current?(nil)).to be false
    end
  end

  describe '#has_ancestor?' do
    before do
      allow(File).to receive(:exist?).and_return(false)
      allow_any_instance_of(described_class).to receive(:shell_parent_pid)
    end

    it 'returns true when target_pid is ancestor' do
      allow_any_instance_of(described_class).to(
        receive(:shell_parent_pid).and_return(200, 100, 1)
      )
      expect(subject.has_ancestor?(300, 100)).to be true
    end

    it 'returns false when target_pid not ancestor' do
      allow_any_instance_of(described_class).to(
        receive(:shell_parent_pid).and_return(999, 1)
      )
      expect(subject.has_ancestor?(300, 100)).to be false
    end
  end
end
