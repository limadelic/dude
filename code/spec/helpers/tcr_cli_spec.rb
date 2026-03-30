require_relative '../spec_helper'
require_relative '../../lib/helpers/cli'
require_relative '../../lib/dudes/tcr'

describe 'tcr command' do
  let(:tcr_instance) { instance_double(Dude::Dudes::Tcr) }

  before do
    allow(Dude::Dudes::Tcr).to receive(:new).and_return(tcr_instance)
  end

  it 'exits with code 0 on success' do
    allow(tcr_instance).to receive(:run).and_return(true)

    cli = Dude::CLI.new
    expect { cli.invoke(:tcr, %w[file.rb]) }.to raise_error(SystemExit) { |error| expect(error.status).to eq(0) }
  end

  it 'exits with code 1 on failure' do
    allow(tcr_instance).to receive(:run).and_return(false)

    cli = Dude::CLI.new
    expect { cli.invoke(:tcr, %w[file.rb]) }.to raise_error(SystemExit) { |error| expect(error.status).to eq(1) }
  end

  it 'passes files to Tcr' do
    allow(tcr_instance).to receive(:run).and_return(true)
    expect(Dude::Dudes::Tcr).to receive(:new).with(%w[lib/foo.rb]).and_return(tcr_instance)

    cli = Dude::CLI.new
    expect { cli.invoke(:tcr, %w[lib/foo.rb]) }.to raise_error(SystemExit)
  end
end
