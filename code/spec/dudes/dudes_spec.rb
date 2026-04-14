require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/dudes'
require 'json'

describe Dude::Dudes::Dudes do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:dudes_dir) { '/proj/.claude/dudes' }
  let(:target) { '/proj/.claude' }
  let(:ppid) { 12345 }

  before do
    stub(Dir).children(anything) { %w[rec] }
    stub(File).symlink?(anything) { true }
    stub(File).readlink(anything) { '/proj/.claude/' }
    stub(File).read(anything) { "---\nicon: 🔴\n---\n" }
    stub(Dude::Dudes::Dudes).pids { { ppid => target } }
    stub(File).exist?(anything) { true }
    stub(JSON).load_file(anything) { {} }
    stub(Process).ppid { ppid }
  end

  describe '#all' do
    it 'returns list of Dude objects' do
      stub(JSON).load_file(anything) { { 'context' => 50 } }

      result = sut.all

      expect(result).to all(be_a(Dude::Dudes::Dude))
      expect(result.first.name).to eq('rec')
    end

    it 'returns empty when no symlinks' do
      stub(Dir).children { [] }

      expect(sut.all).to eq([])
    end

    it 'skips dudes without icon' do
      stub(File).exist?(anything) { false }

      expect(sut.all).to eq([])
    end

    it 'sets dude name from symlink' do
      expect(sut.all.first.name).to eq('rec')
    end
  end

  describe '#current' do
    it 'returns the current dude' do
      expect(sut.current.name).to eq('rec')
    end

    it 'returns nil when no current' do
      stub(File).readlink(anything) { '/other/.claude/' }
      stub(Dude::Dudes::Dudes).pids { { ppid => '/other/.claude' } }
      stub(Process).ppid { 99999 }

      expect(sut.current).to be_nil
    end
  end

  context 'multiple PIDs same target' do
    before do
      stub(JSON).load_file(anything) { { 'context' => 50 } }
      stub(Dude::Dudes::Dudes).pids do
        {
          111 => '/proj/.claude', 222 => '/proj/.claude',
          333 => '/proj/.claude'
        }
      end
    end

    it 'creates one dude per PID' do
      result = sut.all

      expect(result.map(&:name)).to eq(%w[rec rec rec])
      expect(result.map(&:pid)).to match_array([111, 222, 333])
    end
  end

  describe '#resolve_inbox' do
    it 'returns inbox path from symlink target' do
      stub(File).readlink(anything) { '/projects/rec/.claude/' }

      expect(sut.resolve_inbox('rec'))
        .to eq('/projects/rec/.claude/dudes/inbox.json')
    end

    it 'raises when symlink not found' do
      stub(File).symlink?(anything) { false }

      expect { sut.resolve_inbox('missing') }
        .to raise_error("dude 'missing' not found")
    end

    it 'handles symlink trailing slash' do
      stub(File).readlink(anything) { '/projects/rec/.claude/' }

      expect(sut.resolve_inbox('rec'))
        .to eq('/projects/rec/.claude/dudes/inbox.json')
    end
  end

  describe '#read_self_name' do
    it 'reads name from status.json' do
      status_file = '/proj/.claude/dudes/status.json'
      stub(JSON).load_file(status_file) { { 'name' => 'smith' } }

      expect(sut.read_self_name('/proj/.claude/dudes'))
        .to eq('smith')
    end
  end

  describe '#is_current?' do
    let(:process_tree) { Object.new }

    before do
      stub(File).exist?(anything) { false }
      stub(Dude::Dudes::ProcessTree).new { process_tree }
    end

    it 'returns true when pid is in ancestor chain' do
      stub(process_tree).is_current?(100) { true }

      expect(sut.is_current?(100)).to be true
    end

    it 'returns false when pid not in ancestor chain' do
      stub(process_tree).is_current?(100) { false }

      expect(sut.is_current?(100)).to be false
    end

    it 'returns false when pid is nil' do
      stub(process_tree).is_current?(nil) { false }

      expect(sut.is_current?(nil)).to be false
    end
  end

  describe '#is_abiding?' do
    before do
      stub(Dude::Dudes::Dudes).pids { { 1000 => '/proj/.claude' } }
    end

    it 'returns true when abide task exists as child of pid' do
      task_list = [
        { pid: 123, parent_pid: 1000, command: "dude abide #{dudes_dir}" }
      ]
      stub(Dude::Helpers::BackgroundTasks).list { task_list }

      expect(sut.is_abiding?(1000, dudes_dir, target))
        .to be true
    end

    it 'returns false when no abide task' do
      stub(Dude::Helpers::BackgroundTasks).list { [] }

      expect(sut.is_abiding?(1000, dudes_dir, target))
        .to be false
    end

    it 'returns false when task parent is not the pid' do
      task_list = [
        { pid: 123, parent_pid: 999, command: "dude abide #{dudes_dir}" }
      ]
      stub(Dude::Helpers::BackgroundTasks).list { task_list }

      expect(sut.is_abiding?(1000, dudes_dir, target))
        .to be false
    end

    it 'returns false when task is for different dude' do
      task_list = [
        {
          pid: 123, parent_pid: 1000,
          command: 'dude abide /other/.claude/dudes'
        }
      ]
      stub(Dude::Helpers::BackgroundTasks).list { task_list }

      expect(sut.is_abiding?(1000, dudes_dir, target))
        .to be false
    end
  end

  describe '#pids_for_target' do
    it 'returns pids matching target or parent' do
      stub(Dude::Dudes::Dudes).pids do
        {
          100 => '/proj/.claude', 200 => '/proj/.claude',
          300 => '/other/.claude'
        }
      end

      expect(sut.pids_for_target('/proj/.claude'))
        .to match_array([100, 200])
    end

    it 'handles target with trailing slash' do
      stub(Dude::Dudes::Dudes).pids do
        { 100 => '/proj/.claude', 200 => '/proj' }
      end

      expect(sut.pids_for_target('/proj/.claude/'))
        .to match_array([100, 200])
    end

    it 'returns empty when no matching pids' do
      stub(Dude::Dudes::Dudes).pids { { 100 => '/other/.claude' } }

      expect(sut.pids_for_target('/proj/.claude'))
        .to eq([])
    end
  end
end
