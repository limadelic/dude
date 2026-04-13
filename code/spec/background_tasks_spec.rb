require_relative './spec_helper'
require_relative '../lib/dude/helpers/background_tasks'
require_relative '../lib/dude/helpers/process_tree_walker'

describe Dude::Helpers::BackgroundTasks do
  include RR::DSL

  let(:walker) { Object.new }

  before do
    stub(Dude::Helpers::BackgroundTasks).walker { walker }
    stub(Dude::Dudes::Dudes).pids { {} }
  end

  describe '.list' do
    it 'returns empty array when no live dudes' do
      expect(Dude::Helpers::BackgroundTasks.list).to eq([])
    end

    it 'returns process hashes with pid, parent_pid, and command' do
      stub(Dude::Dudes::Dudes).pids { { 1000 => '/proj/.claude' } }
      stub(walker).descendants_with_parents([1000]) \
        { [[2000, 2001], { 2000 => 1000, 2001 => 1000 }] }
      stub(walker).command_for(2000) { "dude abide" }
      stub(walker).command_for(2001) { "dude watch" }

      expect(Dude::Helpers::BackgroundTasks.list).to contain_exactly(
        { pid: 2000, parent_pid: 1000, command: "dude abide" },
        { pid: 2001, parent_pid: 1000, command: "dude watch" }
      )
    end

    it 'handles nested hierarchy with correct parent_pids' do
      stub(Dude::Dudes::Dudes).pids { { 1000 => '/proj/.claude' } }
      stub(walker).descendants_with_parents([1000]) \
        { [[2000, 3000], { 2000 => 1000, 3000 => 2000 }] }
      stub(walker).command_for(2000) { "ruby -e dude" }
      stub(walker).command_for(3000) { "dude watch" }

      expect(Dude::Helpers::BackgroundTasks.list).to contain_exactly(
        { pid: 2000, parent_pid: 1000, command: "ruby -e dude" },
        { pid: 3000, parent_pid: 2000, command: "dude watch" }
      )
    end

    it 'passes all live dude pids to walker' do
      stub(Dude::Dudes::Dudes).pids do
        { 1000 => '/proj1/.claude', 2000 => '/proj2/.claude' }
      end
      stub(walker).descendants_with_parents([1000, 2000]) \
        { [[1001, 2001], { 1001 => 1000, 2001 => 2000 }] }
      stub(walker).command_for(1001) { "dude abide" }
      stub(walker).command_for(2001) { "dude watch" }

      expect(Dude::Helpers::BackgroundTasks.list).to contain_exactly(
        { pid: 1001, parent_pid: 1000, command: "dude abide" },
        { pid: 2001, parent_pid: 2000, command: "dude watch" }
      )
    end
  end

  describe '.kill' do
    it 'sends TERM signal to process' do
      mock(Process).kill('TERM', 12345)

      Dude::Helpers::BackgroundTasks.kill(12345)
    end

    it 'raises on invalid pid' do
      stub(Process).kill('TERM', 99999) { raise Errno::ESRCH }

      expect { Dude::Helpers::BackgroundTasks.kill(99999) }.to raise_error(Errno::ESRCH)
    end
  end
end
