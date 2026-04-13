require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/cli'
require_relative '../../lib/dude/dudes/tcr'

describe Dude::Helpers::Cli do
  include RR::DSL

  let(:sut) { described_class.new }
  let(:tcr_instance) { Object.new }
  let(:dude) { Object.new }
  let(:dudes) { Object.new }
  let(:pub_instance) { Object.new }

  describe '#tcr' do
    before { stub(Dude::Dudes::Tcr).new { tcr_instance } }

    it 'exits with code 0 on success' do
      stub(tcr_instance).run { true }

      expect { sut.invoke(:tcr, %w[file.rb]) }.to(
        raise_error(SystemExit) do |error|
          expect(error.status).to eq(0)
        end
      )
    end

    it 'exits with code 1 on failure' do
      stub(tcr_instance).run { false }

      expect { sut.invoke(:tcr, %w[file.rb]) }.to(
        raise_error(SystemExit) do |error|
          expect(error.status).to eq(1)
        end
      )
    end

    it 'passes files to Tcr' do
      files = %w[lib/foo.rb]
      mock(Dude::Dudes::Tcr).new(files) { tcr_instance }
      mock(tcr_instance).run { true }

      expect { sut.invoke(:tcr, files) }.to raise_error(SystemExit)
    end
  end

  describe '#reply' do
    before do
      stub(Dude::Dudes::Dudes).new { dudes }
      stub(dudes).current { dude }
    end

    it 'calls reply on current dude with to and msg' do
      mock(dude).reply(to: 'sender', msg: 'hello back')

      sut.invoke(:reply, ['sender', 'hello back'])
    end

    it 'raises error when no dude is running' do
      stub(dudes).current { nil }

      expect { sut.invoke(:reply, ['sender', 'hello']) }.to raise_error(
        'No dude running'
      )
    end
  end

  describe '#pub' do
    before do
      stub(Dude::Dudes::Pub).new { pub_instance }
      stub(Dir).pwd { '/proj' }
      stub($stdout).puts
    end

    it 'calls Pub.new with current working directory' do
      mock(Dude::Dudes::Pub).new(target: '/proj') { pub_instance }
      stub(pub_instance).pub { 'myicon' }

      sut.invoke(:pub, ['myicon'])
    end

    it 'calls pub method with name argument' do
      mock(pub_instance).pub('/proj', 'myicon') { 'myicon' }

      sut.invoke(:pub, ['myicon'])
    end

    it 'prints the returned name' do
      stub(pub_instance).pub { 'myicon' }

      expect { sut.invoke(:pub, ['myicon']) }.to output("myicon\n").to_stdout
    end

    it 'uses nil as default name when not provided' do
      mock(pub_instance).pub('/proj', nil) { '/proj' }

      sut.invoke(:pub, [])
    end
  end
end
