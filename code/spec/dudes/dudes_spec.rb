require_relative '../spec_helper'
require_relative '../../lib/dude/dudes/dudes'
require 'json'

describe 'Dude::GLOBAL_DIR' do
  it 'defaults to ~/.claude/dudes expanded' do
    expanded = File.expand_path('~/.claude/dudes')
    expect(Dude::GLOBAL_DIR).to eq(expanded)
  end

  it 'expands tilde in ENV[DUDE_HOME]' do
    home = File.expand_path('~')
    result = File.expand_path(File.join(home, 'custom/dudes'))
    expect(File.expand_path(File.join(home, 'custom/dudes'))).to eq(result)
  end
end

describe Dude::Dudes::Dudes do
  def dudes
    described_class.new
  end

  before do
    allow(Dir).to receive(:children).and_return(%w[rec])
    allow(File).to receive(:symlink?).and_return(true)
    allow(File).to receive(:readlink).and_return('/proj/.claude/')
    pids_map = { 12345 => '/proj/.claude' }
    allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
    allow(File).to receive(:exist?).and_return(true)
    allow(File).to receive(:read).and_return("---\nicon: 🔴\n---\n")
    allow(JSON).to receive(:load_file).and_return({}, [])
    allow(Process).to receive(:ppid).and_return(12345)
  end

  describe '#all' do
    it 'returns list of Dude objects' do
      allow(JSON).to receive(:load_file).and_return({ 'context' => 50 }, [])
      result = dudes.all
      expect(result.length).to eq(1)
      expect(result.first).to be_a(Dude::Dudes::Dude)
    end

    it 'returns empty when no symlinks' do
      allow(Dir).to receive(:children).and_return([])
      expect(dudes.all).to eq([])
    end

    it 'skips dudes without icon' do
      allow(File).to receive(:exist?).and_return(false)
      expect(dudes.all).to eq([])
    end

    it 'sets dude name from symlink' do
      expect(dudes.all.first.name).to eq('rec')
    end
  end

  describe '#current' do
    it 'returns the current dude' do
      expect(dudes.current.name).to eq('rec')
    end

    it 'returns nil when no current' do
      allow(File).to receive(:readlink).and_return('/other/.claude/')
      pids_map = { 12345 => '/other/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
      allow(Process).to receive(:ppid).and_return(99999)
      expect(dudes.current).to be_nil
    end
  end

  describe 'multiple PIDs same target' do
    before do
      allow(Dir).to receive(:children).and_return(%w[rec])
      allow(File).to receive(:symlink?).and_return(true)
      allow(File).to receive(:readlink).and_return('/proj/.claude/')
      allow(File).to receive(:exist?).and_return(true)
      allow(File).to receive(:read).and_return("---\nicon: 🔴\n---\n")
      allow(JSON).to receive(:load_file).and_return({ 'context' => 50 }, [])
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(
        {
          111 => '/proj/.claude',
          222 => '/proj/.claude',
          333 => '/proj/.claude'
        }
      )
    end

    it 'creates one dude per PID' do
      result = dudes.all
      expect(result.length).to eq(3)
      expect(result.map(&:name)).to eq(%w[rec rec rec])
      expect(result.map(&:pid)).to match_array([111, 222, 333])
    end
  end

  describe '#resolve_inbox' do
    it 'returns inbox path from symlink target' do
      allow(File).to receive(:readlink).and_return('/projects/rec/.claude/')
      result = dudes.resolve_inbox('rec')
      expect(result).to eq('/projects/rec/.claude/dudes/inbox.json')
    end

    it 'raises when symlink not found' do
      allow(File).to receive(:symlink?).and_return(false)
      error_msg = "dude 'missing' not found"
      expect { dudes.resolve_inbox('missing') }.to raise_error(error_msg)
    end

    it 'handles symlink trailing slash' do
      allow(File).to receive(:readlink).and_return('/projects/rec/.claude/')
      result = dudes.resolve_inbox('rec')
      expect(result).to eq('/projects/rec/.claude/dudes/inbox.json')
    end
  end

  describe '#read_self_name' do
    it 'reads name from status.json' do
      status_file = '/proj/.claude/dudes/status.json'
      allow(JSON).to receive(:load_file).with(status_file)
        .and_return({ 'name' => 'smith' })
      result = dudes.read_self_name('/proj/.claude/dudes')
      expect(result).to eq('smith')
    end
  end

  describe '#is_current?' do
    before do
      allow(File).to receive(:exist?).and_return(false)
      process_tree_class = Dude::Dudes::ProcessTree
      allow_any_instance_of(process_tree_class).to receive(:shell_parent_pid)
    end

    it 'returns true when pid is in ancestor chain' do
      allow(Process).to receive(:ppid).and_return(200)
      process_tree_class = Dude::Dudes::ProcessTree
      allow_any_instance_of(process_tree_class).to receive(:shell_parent_pid)
        .and_return(100, 1)
      pids_map = { 100 => '/proj/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
      expect(dudes.is_current?(100)).to be true
    end

    it 'returns false when pid not in ancestor chain' do
      allow(Process).to receive(:ppid).and_return(200)
      process_tree_class = Dude::Dudes::ProcessTree
      allow_any_instance_of(process_tree_class).to receive(:shell_parent_pid)
        .and_return(999, 1)
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return({})
      expect(dudes.is_current?(100)).to be false
    end

    it 'returns false when pid is nil' do
      expect(dudes.is_current?(nil)).to be false
    end
  end

  describe '#is_abiding?' do
    before do
      pids_map = { 1000 => '/proj/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
    end

    it 'returns true when abide task exists as child of pid' do
      task_list = [
        {
          pid: 123, parent_pid: 1000,
          command: 'dude abide /proj/.claude/dudes'
        }
      ]
      stub = allow(Dude::Helpers::BackgroundTasks).to receive(:list)
      stub.and_return(task_list)
      result = dudes.is_abiding?(1000, '/proj/.claude/dudes', '/proj/.claude')
      expect(result).to be true
    end

    it 'returns false when no abide task' do
      allow(Dude::Helpers::BackgroundTasks).to receive(:list).and_return([])
      result = dudes.is_abiding?(1000, '/proj/.claude/dudes', '/proj/.claude')
      expect(result).to be false
    end

    it 'returns false when task parent is not the pid' do
      task_list = [
        {
          pid: 123, parent_pid: 999,
          command: 'dude abide /proj/.claude/dudes'
        }
      ]
      stub = allow(Dude::Helpers::BackgroundTasks).to receive(:list)
      stub.and_return(task_list)
      result = dudes.is_abiding?(1000, '/proj/.claude/dudes', '/proj/.claude')
      expect(result).to be false
    end

    it 'returns false when task is for different dude' do
      task_list = [
        {
          pid: 123, parent_pid: 1000,
          command: 'dude abide /other/.claude/dudes'
        }
      ]
      stub = allow(Dude::Helpers::BackgroundTasks).to receive(:list)
      stub.and_return(task_list)
      result = dudes.is_abiding?(1000, '/proj/.claude/dudes', '/proj/.claude')
      expect(result).to be false
    end
  end

  describe '#pids_for_target' do
    it 'returns pids matching target or parent' do
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(
        {
          100 => '/proj/.claude',
          200 => '/proj/.claude',
          300 => '/other/.claude'
        }
      )
      result = dudes.pids_for_target('/proj/.claude')
      expect(result).to match_array([100, 200])
    end

    it 'handles target with trailing slash' do
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(
        {
          100 => '/proj/.claude',
          200 => '/proj'
        }
      )
      result = dudes.pids_for_target('/proj/.claude/')
      expect(result).to match_array([100, 200])
    end

    it 'returns empty when no matching pids' do
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(
        {
          100 => '/other/.claude'
        }
      )
      result = dudes.pids_for_target('/proj/.claude')
      expect(result).to eq([])
    end
  end
end
