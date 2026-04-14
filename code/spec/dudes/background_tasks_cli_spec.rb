require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/background_tasks_cli"

describe Dude::Dudes::BackgroundTasksCli do
  include RR::DSL

  let(:sut) { described_class.new }

  before { stub(Dude::Helpers::BackgroundTasks).list { [] } }

  describe '#list' do
    it 'formats and outputs running processes' do
      stub(Dude::Helpers::BackgroundTasks).list do
        [
          { pid: 1234, parent_pid: 1000, command: 'dude abide' },
          { pid: 5678, parent_pid: 1000, command: 'dude watch' }
        ]
      end

      expect { sut.list }
        .to output("1234 dude abide\n5678 dude watch\n").to_stdout
    end

    it 'outputs message when no processes running' do
      expect { sut.list }
        .to output("No background tasks\n").to_stdout
    end
  end

  describe '#kill' do
    it 'terminates process by pid' do
      mock(Dude::Helpers::BackgroundTasks).kill(12345)

      sut.kill('12345')
    end
  end
end
