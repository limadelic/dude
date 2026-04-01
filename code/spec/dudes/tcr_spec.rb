require_relative '../spec_helper'
require_relative "../../lib/dude/dudes/tcr"

describe 'Dude::Dudes::Tcr' do
  let(:tcr) { Dude::Dudes::Tcr.new(%w[file.rb]) }
  let(:tests_runner) { instance_double(Dude::Dudes::TestsRunner) }
  let(:linter) { instance_double(Dude::Dudes::Linter) }
  before do
    allow(Dude::Dudes::TestsRunner).to receive(:new).and_return(tests_runner)
    allow(Dude::Dudes::Linter).to receive(:new).and_return(linter)
    allow(Dude::Dudes::GitStageCommit).to receive(:new)
      .and_return(instance_double(Dude::Dudes::GitStageCommit, execute: nil))
    allow(Dude::Dudes::GitRevert).to receive(:new)
      .and_return(instance_double(Dude::Dudes::GitRevert, execute: nil))
    allow(tests_runner).to receive(:pass?).and_return(true)
    allow(linter).to receive(:pass?).and_return(true)
  end
  it { expect(tcr.run).to eq(true) }
  it 'returns false when tests fail' do
    allow(tests_runner).to receive(:pass?).and_return(false)
    expect(tcr.run).to eq(false)
  end
  it 'returns false when lint fails' do
    allow(linter).to receive(:pass?).and_return(false)
    expect(tcr.run).to eq(false)
  end
end
