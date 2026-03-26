require_relative './spec_helper'
require_relative '../lib/helpers/background_tasks'

describe BackgroundTasks do
  describe '.list' do
    before do
      allow(BackgroundTasks).to receive(:`).and_return("")
    end

    it 'returns empty array when no live dudes' do
      result = BackgroundTasks.list
      expect(result).to eq([])
    end

    it 'returns process hashes with pid, parent_pid, and command' do
      allow(Dude::Dudes).to receive(:pids).and_return({ 1000 => '/proj/.claude' })
      allow(BackgroundTasks).to receive(:`).with('pgrep -P 1000').and_return("2000\n")
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 2000').and_return("dude abide\n")

      result = BackgroundTasks.list
      expect(result).to contain_exactly({ pid: 2000, parent_pid: 1000, command: "dude abide" })
    end

    it 'returns multiple children with commands' do
      allow(Dude::Dudes).to receive(:pids).and_return({ 1000 => '/proj/.claude' })
      allow(BackgroundTasks).to receive(:`).with('pgrep -P 1000').and_return("2000\n2001\n")
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 2000').and_return("dude abide\n")
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 2001').and_return("dude watch\n")

      result = BackgroundTasks.list
      expect(result).to contain_exactly(
        { pid: 2000, parent_pid: 1000, command: "dude abide" },
        { pid: 2001, parent_pid: 1000, command: "dude watch" }
      )
    end

    it 'returns grandchildren with commands and correct parent_pid' do
      allow(Dude::Dudes).to receive(:pids).and_return({ 1000 => '/proj/.claude' })
      allow(BackgroundTasks).to receive(:`).with('pgrep -P 1000').and_return("2000\n")
      allow(BackgroundTasks).to receive(:`).with('pgrep -P 2000').and_return("3000\n")
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 2000').and_return("ruby -e dude\n")
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 3000').and_return("dude watch\n")

      result = BackgroundTasks.list
      expect(result).to contain_exactly(
        { pid: 2000, parent_pid: 1000, command: "ruby -e dude" },
        { pid: 3000, parent_pid: 2000, command: "dude watch" }
      )
    end

    it 'handles no descendants (leaf process)' do
      allow(Dude::Dudes).to receive(:pids).and_return({ 1000 => '/proj/.claude' })
      allow(BackgroundTasks).to receive(:`).with('pgrep -P 1000').and_return("")

      result = BackgroundTasks.list
      expect(result).to eq([])
    end

    it 'handles whitespace in commands' do
      allow(Dude::Dudes).to receive(:pids).and_return({ 1000 => '/proj/.claude' })
      allow(BackgroundTasks).to receive(:`).with('pgrep -P 1000').and_return("2000\n")
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 2000').and_return("  dude abide  \n")

      result = BackgroundTasks.list
      expect(result).to contain_exactly({ pid: 2000, parent_pid: 1000, command: "dude abide" })
    end

    it 'discovers multiple live dude pids and walks children for each' do
      allow(Dude::Dudes).to receive(:pids).and_return(
        { 1000 => '/proj1/.claude', 2000 => '/proj2/.claude' }
      )
      allow(BackgroundTasks).to receive(:`).with('pgrep -P 1000').and_return("1001\n")
      allow(BackgroundTasks).to receive(:`).with('pgrep -P 2000').and_return("2001\n")
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 1001').and_return("dude abide\n")
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 2001').and_return("dude watch\n")

      result = BackgroundTasks.list
      expect(result).to contain_exactly(
        { pid: 1001, parent_pid: 1000, command: "dude abide" },
        { pid: 2001, parent_pid: 2000, command: "dude watch" }
      )
    end

  end

  describe '.kill' do
    it 'sends TERM signal to process' do
      expect(Process).to receive(:kill).with('TERM', 12345)
      BackgroundTasks.kill(12345)
    end

    it 'raises on invalid pid' do
      expect(Process).to receive(:kill).with('TERM', 99999).and_raise(Errno::ESRCH)
      expect { BackgroundTasks.kill(99999) }.to raise_error(Errno::ESRCH)
    end
  end

  describe '.command_for_pid (integration)' do
    it 'uses command keyword instead of cmd for cross-platform support' do
      # macOS and Linux both support 'command' keyword
      # This test ensures we're not using 'cmd' which fails on macOS
      allow(BackgroundTasks).to receive(:`).with('ps -o command= -p 2000').and_return("dude abide\n")
      result = BackgroundTasks.send(:command_for_pid, 2000)
      expect(result).to eq("dude abide")
    end
  end
end
