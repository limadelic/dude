require_relative './spec_helper'
require_relative '../lib/dude/helpers/cli'

describe Dude::Helpers::Cli do
  describe '#abide' do
    let(:cli) { Dude::Helpers::Cli.new }

    before do
      allow(Dir).to receive(:pwd).and_return('/tmp/test_dude')
      allow_any_instance_of(Dude::Helpers::Wait).to receive(:until).and_yield
      allow(Dude::Dudes::Dudes).to receive(:pids).and_return(
        1000 => '/tmp/test_dude'
      )
      allow(Process).to receive(:kill)
    end

    context 'when no other abide processes exist' do
      it 'watches and returns first message' do
        allow(Dude::Helpers::BackgroundTasks).to receive(:list).and_return([])

        dude_mock = instance_double('Dude::Dudes::Dude')
        allow(dude_mock).to receive(:abide).and_return('"result message"')
        dudes_mock = instance_double('Dude::Dudes::Dudes')
        allow(dudes_mock).to receive(:current).and_return(dude_mock)
        allow(Dude::Dudes::Dudes).to receive(:new).and_return(dudes_mock)

        output = capture_output { cli.abide }
        expect(output).to include('result message')
      end
    end

    context 'when other abide processes exist' do
      it 'kills duplicate processes and returns early' do
        allow(Dude::Helpers::BackgroundTasks).to receive(:list).and_return(
          [
            {
              pid: 1, parent_pid: 1000,
              command: 'dude abide'
            },
            {
              pid: 2, parent_pid: 1000,
              command: 'dude abide'
            },
            {
              pid: 3, parent_pid: 1000,
              command: 'dude other'
            }
          ]
        )
        allow(Process).to receive(:pid).and_return(1)
        expect(Dude::Helpers::BackgroundTasks).to receive(:kill).with(2)

        # Create real Dude with mocked inbox and registry
        inbox_mock = instance_double('Dude::Dudes::Inbox')
        allow(inbox_mock).to receive(:first_new).and_return(nil)

        dude = Dude::Dudes::Dude.new(
          inbox: inbox_mock,
          status: {},
          dude_dir: '/tmp/test_dude',
          target: '/tmp/test_dude',
          name: 'test',
          registry: instance_double('Registry')
        )

        dudes_mock = instance_double('Dude::Dudes::Dudes')
        allow(dudes_mock).to receive(:current).and_return(dude)
        allow(Dude::Dudes::Dudes).to receive(:new).and_return(dudes_mock)

        capture_output { cli.abide }
      end

      it 'does not kill the current process' do
        allow(Dude::Helpers::BackgroundTasks).to receive(:list).and_return(
          [
            {
              pid: 1, parent_pid: 1000,
              command: 'dude abide'
            },
            {
              pid: 2, parent_pid: 1000,
              command: 'dude abide'
            }
          ]
        )
        allow(Process).to receive(:pid).and_return(1)
        expect(Dude::Helpers::BackgroundTasks).to receive(:kill).with(2)

        # Create real Dude with mocked inbox and registry
        inbox_mock = instance_double('Dude::Dudes::Inbox')
        allow(inbox_mock).to receive(:first_new).and_return(nil)

        dude = Dude::Dudes::Dude.new(
          inbox: inbox_mock,
          status: {},
          dude_dir: '/tmp/test_dude',
          target: '/tmp/test_dude',
          name: 'test',
          registry: instance_double('Registry')
        )

        dudes_mock = instance_double('Dude::Dudes::Dudes')
        allow(dudes_mock).to receive(:current).and_return(dude)
        allow(Dude::Dudes::Dudes).to receive(:new).and_return(dudes_mock)

        capture_output { cli.abide }
      end
    end
  end

  describe '#sub' do
    let(:cli) { Dude::Helpers::Cli.new }
    let(:dude_mock) { instance_double('Dude::Dudes::Dude') }
    let(:dudes_mock) { instance_double('Dude::Dudes::Dudes') }

    before do
      allow(dudes_mock).to receive(:current).and_return(dude_mock)
      allow(Dude::Dudes::Dudes).to receive(:new).and_return(dudes_mock)
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
