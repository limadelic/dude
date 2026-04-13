require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/process_tree"

describe Dude::Dudes::ProcessTree do
  include RR::DSL

  let(:sut) { described_class.new }

  before do
    stub(File).exist? { false }
    stub(Process).ppid { 200 }
    stub(sut).shell_parent_pid(200) { 100 }
    stub(sut).shell_parent_pid(100) { 1 }
  end

  describe '.is_current?' do
    it 'returns true when pid is in ancestor chain' do
      stub(described_class).new { sut }

      expect(described_class.is_current?(100)).to be true
    end
  end

  describe '#is_current?' do
    it 'returns true when pid is in ancestor chain' do
      expect(sut.is_current?(100)).to be true
    end

    it 'returns false when pid not in ancestor chain' do
      stub(sut).shell_parent_pid(200) { 999 }
      stub(sut).shell_parent_pid(999) { 1 }

      expect(sut.is_current?(100)).to be false
    end

    it 'returns false when pid is nil' do
      expect(sut.is_current?(nil)).to be false
    end
  end

  describe '#has_ancestor?' do
    before do
      stub(sut).shell_parent_pid(300) { 200 }
      stub(sut).shell_parent_pid(200) { 100 }
      stub(sut).shell_parent_pid(100) { 1 }
    end

    it 'returns true when target_pid is ancestor' do
      expect(sut.has_ancestor?(300, 100)).to be true
    end

    it 'returns false when target_pid not ancestor' do
      stub(sut).shell_parent_pid(300) { 999 }
      stub(sut).shell_parent_pid(999) { 1 }

      expect(sut.has_ancestor?(300, 100)).to be false
    end
  end
end
