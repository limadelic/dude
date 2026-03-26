require_relative './spec_helper'
require_relative '../lib/helpers/background_tasks'
require_relative '../lib/helpers/wait'
require_relative '../lib/helpers/cli'

describe Dude::CLI do
  describe '#abide' do
    let(:cli) { Dude::CLI.new }

    before do
      allow(Dir).to receive(:pwd).and_return('/tmp/test_dude')
      allow_any_instance_of(Helpers::Wait).to receive(:until).and_yield
      allow(Dude::Dudes).to receive(:pids).and_return(
        1000 => '/tmp/test_dude'
      )
      allow(Process).to receive(:kill)
end

    context 'when no other abide processes exist' do
      it 'watches and returns first message' do
        allow(BackgroundTasks).to receive(:list).and_return([])

        dude_mock = instance_double('Dude::Dudes::Dude')
        allow(dude_mock).to receive(:watch).and_return('result message')
        dudes_mock = instance_double('Dude::Dudes')
        allow(dudes_mock).to receive(:current).and_return(dude_mock)
        allow(Dude::Dudes).to receive(:new).and_return(dudes_mock)

        output = capture_output { cli.abide }
        expect(output).to include('result message')
      end
    end

    context 'when other abide processes exist' do
      it 'kills duplicate processes and returns early' do
        allow(BackgroundTasks).to receive(:list).and_return([
          { pid: 1, parent_pid: 1000, command: 'dude abide' },
          { pid: 2, parent_pid: 1000, command: 'dude abide' },
          { pid: 3, parent_pid: 1000, command: 'dude other' }
        ])
        allow(Process).to receive(:pid).and_return(1)

        expect(BackgroundTasks).to receive(:kill).with(2)

        capture_output { cli.abide }
      end

      it 'does not kill the current process' do
        allow(BackgroundTasks).to receive(:list).and_return([
          { pid: 1, parent_pid: 1000, command: 'dude abide' },
          { pid: 2, parent_pid: 1000, command: 'dude abide' }
        ])
        allow(Process).to receive(:pid).and_return(1)

        expect(BackgroundTasks).to receive(:kill).with(2)

        capture_output { cli.abide }
      end
    end
  end

  describe '#sub' do
    let(:cli) { Dude::CLI.new }
    let(:dude_mock) { instance_double('Dude::Dudes::Dude') }
    let(:dudes_mock) { instance_double('Dude::Dudes') }

    before do
      allow(dudes_mock).to receive(:current).and_return(dude_mock)
      allow(Dude::Dudes).to receive(:new).and_return(dudes_mock)
    end

    it 'registers as a sub dude with provided name' do
      expect(dude_mock).to receive(:sub).with('myapp').and_return('myapp')

      output = capture_output { cli.sub('myapp') }
      expect(output).to include('myapp')
    end

    it 'registers as a sub dude with default name when not provided' do
      expect(dude_mock).to receive(:sub).with(nil).and_return('subfolder')

      output = capture_output { cli.sub }
      expect(output).to include('subfolder')
    end

    it 'raises error when no dude is running' do
      allow(dudes_mock).to receive(:current).and_return(nil)

      expect { cli.sub('myapp') }.to raise_error('No dude running')
    end
  end

end
