require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/background_tasks_cli"

describe Dude::Dudes::BackgroundTasksCli do
  let(:cli) { described_class.new }

  describe '#list' do
    it 'shows discovered processes' do
      allow(Dude::Helpers::BackgroundTasks).to receive(:list).and_return(
        [
          {
            pid: 1234, parent_pid: 1000,
            command: 'dude abide'
          },
          {
            pid: 5678, parent_pid: 1000,
            command: 'dude watch'
          }
        ]
      )

      expect {
        cli.list
      }.to output("1234 dude abide\n5678 dude watch\n").to_stdout
    end

    it 'shows message when no processes found' do
      allow(Dude::Helpers::BackgroundTasks).to receive(:list).and_return([])

      expect { cli.list }.to output("No background tasks\n").to_stdout
    end
  end

  describe '#kill' do
    it 'kills a process by pid' do
      expect(Dude::Helpers::BackgroundTasks).to receive(:kill).with(12345)

      cli.kill('12345')
    end

    it 'converts pid string to integer' do
      expect(Dude::Helpers::BackgroundTasks).to receive(:kill).with(12345)

      cli.kill('12345')
    end
  end
end
