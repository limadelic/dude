require_relative './spec_helper'
require_relative '../lib/dude/helpers/background_tasks'
require_relative '../lib/dude/helpers/process_tree_walker'

describe Dude::Helpers::BackgroundTasks do
  describe '.list' do
    let(:walker_mock) { instance_double('Dude::Helpers::ProcessTreeWalker') }

    before do
      allow(Dude::Helpers::ProcessTreeWalker).to receive(:new)
        .and_return(walker_mock)
      Dude::Helpers::BackgroundTasks.instance_variable_set(:@walker, nil)
    end

    it 'returns empty array when no live dudes' do
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return({})
      result = Dude::Helpers::BackgroundTasks.list
      expect(result).to eq([])
    end

    it 'returns process hashes with pid, parent_pid, and command' do
      pids_map = { 1000 => '/proj/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
      allow(walker_mock).to receive(:descendants_with_parents).with([1000])
        .and_return([[2000], { 2000 => 1000 }])
      allow(walker_mock).to receive(:command_for).with(2000)
        .and_return("dude abide")

      result = Dude::Helpers::BackgroundTasks.list
      expect(result).to contain_exactly(
        { pid: 2000, parent_pid: 1000, command: "dude abide" }
      )
    end

    it 'returns multiple children with commands' do
      pids_map = { 1000 => '/proj/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
      allow(walker_mock).to receive(:descendants_with_parents).with([1000])
        .and_return([
          [2000, 2001],
          { 2000 => 1000, 2001 => 1000 }
        ]
                   )
      allow(walker_mock).to receive(:command_for).with(2000)
        .and_return("dude abide")
      allow(walker_mock).to receive(:command_for).with(2001)
        .and_return("dude watch")

      result = Dude::Helpers::BackgroundTasks.list
      expect(result).to contain_exactly(
        { pid: 2000, parent_pid: 1000, command: "dude abide" },
        { pid: 2001, parent_pid: 1000, command: "dude watch" }
      )
    end

    it 'returns grandchildren with commands and correct parent_pid' do
      pids_map = { 1000 => '/proj/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
      allow(walker_mock).to receive(:descendants_with_parents).with([1000])
        .and_return([
          [2000, 3000],
          { 2000 => 1000, 3000 => 2000 }
        ]
                   )
      allow(walker_mock).to receive(:command_for).with(2000)
        .and_return("ruby -e dude")
      allow(walker_mock).to receive(:command_for).with(3000)
        .and_return("dude watch")

      result = Dude::Helpers::BackgroundTasks.list
      expect(result).to contain_exactly(
        { pid: 2000, parent_pid: 1000, command: "ruby -e dude" },
        { pid: 3000, parent_pid: 2000, command: "dude watch" }
      )
    end

    it 'handles no descendants (leaf process)' do
      pids_map = { 1000 => '/proj/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
      allow(walker_mock).to receive(:descendants_with_parents).with([1000])
        .and_return([[], {}])

      result = Dude::Helpers::BackgroundTasks.list
      expect(result).to eq([])
    end

    it 'handles whitespace in commands' do
      pids_map = { 1000 => '/proj/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
      allow(walker_mock).to receive(:descendants_with_parents).with([1000])
        .and_return([[2000], { 2000 => 1000 }])
      allow(walker_mock).to receive(:command_for).with(2000)
        .and_return("dude abide")

      result = Dude::Helpers::BackgroundTasks.list
      expect(result).to contain_exactly(
        { pid: 2000, parent_pid: 1000, command: "dude abide" }
      )
    end

    it 'discovers multiple live dude pids and walks children for each' do
      pids_map = { 1000 => '/proj1/.claude', 2000 => '/proj2/.claude' }
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(pids_map)
      pids = [1000, 2000]
      allow(walker_mock).to receive(:descendants_with_parents).with(pids)
        .and_return([
          [1001, 2001],
          { 1001 => 1000, 2001 => 2000 }
        ]
                   )
      allow(walker_mock).to receive(:command_for).with(1001)
        .and_return("dude abide")
      allow(walker_mock).to receive(:command_for).with(2001)
        .and_return("dude watch")

      result = Dude::Helpers::BackgroundTasks.list
      expect(result).to contain_exactly(
        { pid: 1001, parent_pid: 1000, command: "dude abide" },
        { pid: 2001, parent_pid: 2000, command: "dude watch" }
      )
    end
  end

  describe '.kill' do
    it 'sends TERM signal to process' do
      expect(Process).to receive(:kill).with('TERM', 12345)
      Dude::Helpers::BackgroundTasks.kill(12345)
    end

    it 'raises on invalid pid' do
      expect(Process).to receive(:kill).with('TERM', 99999).and_raise(Errno::ESRCH)
      expect { Dude::Helpers::BackgroundTasks.kill(99999) }.to raise_error(Errno::ESRCH)
    end
  end
end
