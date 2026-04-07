require_relative '../spec_helper'
require_relative '../../lib/dude/helpers/cli'
require_relative '../../lib/dude/dudes/tcr'

describe 'tcr command' do
  let(:tcr_instance) { instance_double(Dude::Dudes::Tcr) }

  before do
    allow(Dude::Dudes::Tcr).to receive(:new).and_return(tcr_instance)
  end

  it 'exits with code 0 on success' do
    allow(tcr_instance).to receive(:run).and_return(true)

    cli = Dude::Helpers::Cli.new
    expect { cli.invoke(:tcr, %w[file.rb]) }.to(
      raise_error(SystemExit) do |error|
        expect(error.status).to eq(0)
      end
    )
  end

  it 'exits with code 1 on failure' do
    allow(tcr_instance).to receive(:run).and_return(false)

    cli = Dude::Helpers::Cli.new
    expect { cli.invoke(:tcr, %w[file.rb]) }.to(
      raise_error(SystemExit) do |error|
        expect(error.status).to eq(1)
      end
    )
  end

  it 'passes files to Tcr' do
    allow(tcr_instance).to receive(:run).and_return(true)
    expect(Dude::Dudes::Tcr).to receive(:new).with(%w[lib/foo.rb])
      .and_return(tcr_instance)

    cli = Dude::Helpers::Cli.new
    expect { cli.invoke(:tcr, %w[lib/foo.rb]) }.to raise_error(SystemExit)
  end
end

describe 'reply command' do
  let(:dude_mock) { instance_double('Dude::Dudes::Dude') }
  let(:dudes_mock) { instance_double('Dude::Dudes::Dudes') }

  before do
    allow(dudes_mock).to receive(:current).and_return(dude_mock)
    allow(Dude::Dudes::Dudes).to receive(:new).and_return(dudes_mock)
  end

  it 'calls reply on current dude with to and msg' do
    expect(dude_mock).to receive(:reply).with(to: 'sender', msg: 'hello back')

    cli = Dude::Helpers::Cli.new
    cli.invoke(:reply, ['sender', 'hello back'])
  end

  it 'raises error when no dude is running' do
    allow(dudes_mock).to receive(:current).and_return(nil)

    cli = Dude::Helpers::Cli.new
    expect { cli.invoke(:reply, ['sender', 'hello']) }.to raise_error(
      'No dude running'
    )
  end
end

describe 'pub command' do
  let(:pub_instance) { instance_double(Dude::Dudes::Pub) }

  before do
    allow(Dude::Dudes::Pub).to receive(:new).and_return(pub_instance)
  end

  it 'calls Pub.new with current working directory' do
    allow(pub_instance).to receive(:pub).and_return('myicon')
    allow(Dir).to receive(:pwd).and_return('/proj')

    expect(Dude::Dudes::Pub).to receive(:new).with(target: '/proj')
      .and_return(pub_instance)

    cli = Dude::Helpers::Cli.new
    cli.invoke(:pub, ['myicon'])
  end

  it 'calls pub method with name argument' do
    allow(Dir).to receive(:pwd).and_return('/proj')
    allow(pub_instance).to receive(:pub).and_return('myicon')

    expect(pub_instance).to receive(:pub).with('/proj', 'myicon')
      .and_return('myicon')

    cli = Dude::Helpers::Cli.new
    cli.invoke(:pub, ['myicon'])
  end

  it 'prints the returned name' do
    allow(Dir).to receive(:pwd).and_return('/proj')
    allow(pub_instance).to receive(:pub).and_return('myicon')

    cli = Dude::Helpers::Cli.new
    expect { cli.invoke(:pub, ['myicon']) }.to output("myicon\n").to_stdout
  end

  it 'uses nil as default name when not provided' do
    allow(Dir).to receive(:pwd).and_return('/proj')
    allow(pub_instance).to receive(:pub).and_return('/proj')

    expect(pub_instance).to receive(:pub).with('/proj', nil).and_return('/proj')

    cli = Dude::Helpers::Cli.new
    cli.invoke(:pub, [])
  end
end
